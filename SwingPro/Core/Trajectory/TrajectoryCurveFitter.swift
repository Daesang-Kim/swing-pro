import Foundation

/// 공 탐지가 끊긴 이후 구간을, 직전까지 탐지된 궤적의 흐름(방향·곡률)을 바탕으로
/// 자연스럽게 이어지는 곡선으로 외삽한다. 정확한 물리 시뮬레이션이 아니라
/// 시각적으로 자연스러운 트레이서 표시가 목적이다.
enum TrajectoryCurveFitter {
    /// 외삽에 사용할 최근 탐지 포인트 최소 개수. 이보다 적으면 곡선 적합이 불안정하다.
    static let minimumPointsForFit = 3

    /// `detectedPoints`의 마지막 구간 경향을 2차 곡선으로 근사해 `extraDuration`만큼 미래 지점을 생성한다.
    static func extrapolate(
        detectedPoints: [TrajectoryPoint],
        extraDuration: TimeInterval,
        sampleInterval: TimeInterval = 1.0 / 60.0
    ) -> [TrajectoryPoint] {
        guard detectedPoints.count >= minimumPointsForFit, extraDuration > 0 else { return [] }

        let recent = Array(detectedPoints.suffix(max(minimumPointsForFit, min(detectedPoints.count, 10))))
        let times = recent.map(\.timestamp)
        guard let xCoefficients = quadraticFit(times: times, values: recent.map(\.x)),
              let yCoefficients = quadraticFit(times: times, values: recent.map(\.y)),
              let lastTimestamp = times.last else { return [] }

        var result: [TrajectoryPoint] = []
        var t = sampleInterval
        while t <= extraDuration {
            let futureTime = lastTimestamp + t
            let x = xCoefficients.evaluate(at: futureTime)
            let y = yCoefficients.evaluate(at: futureTime)
            result.append(TrajectoryPoint(x: x, y: y, timestamp: futureTime))
            t += sampleInterval
        }
        return result
    }

    struct QuadraticCoefficients {
        let a: Double
        let b: Double
        let c: Double

        func evaluate(at t: Double) -> Double {
            a * t * t + b * t + c
        }
    }

    /// 최소자승법으로 y = a*t^2 + b*t + c 계수를 구한다. 포인트가 부족하거나 특이행렬이면 nil.
    static func quadraticFit(times: [Double], values: [Double]) -> QuadraticCoefficients? {
        guard times.count == values.count, times.count >= 3 else { return nil }

        let n = Double(times.count)
        let sumT = times.reduce(0, +)
        let sumT2 = times.reduce(0) { $0 + $1 * $1 }
        let sumT3 = times.reduce(0) { $0 + $1 * $1 * $1 }
        let sumT4 = times.reduce(0) { $0 + $1 * $1 * $1 * $1 }
        let sumY = values.reduce(0, +)
        let sumTY = zip(times, values).reduce(0) { $0 + $1.0 * $1.1 }
        let sumT2Y = zip(times, values).reduce(0) { $0 + $1.0 * $1.0 * $1.1 }

        // Normal equations for [a, b, c]:
        // [sumT4 sumT3 sumT2] [a]   [sumT2Y]
        // [sumT3 sumT2 sumT ] [b] = [sumTY ]
        // [sumT2 sumT  n    ] [c]   [sumY  ]
        let matrix = [
            [sumT4, sumT3, sumT2],
            [sumT3, sumT2, sumT],
            [sumT2, sumT, n],
        ]
        let rhs = [sumT2Y, sumTY, sumY]

        guard let solution = solve3x3(matrix: matrix, rhs: rhs) else { return nil }
        return QuadraticCoefficients(a: solution[0], b: solution[1], c: solution[2])
    }

    /// 크래머 공식을 이용한 3x3 연립방정식 풀이.
    private static func solve3x3(matrix: [[Double]], rhs: [Double]) -> [Double]? {
        let det = determinant3x3(matrix)
        guard abs(det) > 1e-9 else { return nil }

        func replacingColumn(_ column: Int) -> [[Double]] {
            matrix.enumerated().map { rowIndex, row in
                var newRow = row
                newRow[column] = rhs[rowIndex]
                return newRow
            }
        }

        let x0 = determinant3x3(replacingColumn(0)) / det
        let x1 = determinant3x3(replacingColumn(1)) / det
        let x2 = determinant3x3(replacingColumn(2)) / det
        return [x0, x1, x2]
    }

    private static func determinant3x3(_ m: [[Double]]) -> Double {
        m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
            - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
            + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
    }
}
