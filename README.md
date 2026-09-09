# Swing Pro (iOS)

골프 스윙을 자동으로 인식해 스윙 전후 구간을 자동으로 녹화·저장하고, 온디바이스 포즈 분석으로
교정 피드백과 점수를 제공하는 iOS 앱. 전체 요구사양은 [`docs/requirements.md`](docs/requirements.md) 참고.

## 기술 스택

| 영역 | 프레임워크 |
|---|---|
| 언어/UI | Swift + SwiftUI |
| 카메라/프리롤 버퍼링 | AVFoundation |
| 스윙 인식(포즈 추정) | Vision (`VNDetectHumanBodyPoseRequest`) |
| 퍼팅 거리 측정 | ARKit (평면 인식 + hit-testing) |
| 영상 저장 | Photos (PHAsset) |
| 로컬 DB | Core Data |

플랫폼은 iOS 네이티브로 우선 개발하며, 판별 로직(스윙 규칙, 점수 계산, 기준값 비교)은 최대한
플랫폼 독립적인 순수 Swift(Foundation)로 작성해 추후 Android 포팅 시 재사용할 수 있게 했다.

## 프로젝트 열기

이 저장소는 `.xcodeproj`를 커밋하지 않고 [XcodeGen](https://github.com/yonaskolb/XcodeGen)으로
`project.yml`에서 생성하는 방식을 사용한다 (병합 충돌 방지, 설정 변경 이력 추적 용이).

```bash
brew install xcodegen   # 최초 1회
cd SwingPro-repo-root
xcodegen generate
open SwingPro.xcodeproj
```

Xcode에서 `SwingPro` 스킴으로 빌드/실행, `SwingProTests` 스킴으로 유닛 테스트를 실행한다.
카메라·Vision·ARKit 관련 기능은 시뮬레이터에서 동작하지 않으므로 실기기 테스트가 필요하다.

## 폴더 구조

```
SwingPro/
  App/                 앱 진입점(SwingProApp), 전역 상태(AppState) · 네비게이션 라우팅
  Domain/
    Models/            enum 등 값 타입 (SessionMode, ShotType, CameraView, SwingCheckpoint ...)
    Entities/           DB 스키마를 그대로 미러링한 Codable 구조체 (UserProfile, SwingClip ...)
  Core/
    Camera/            AVFoundation 캡처, 프리롤 순환 버퍼, 스윙 자동 캡처 파이프라인
    Pose/              Vision 포즈 추정, 스윙 구간(P1~P10) 판별, 촬영 방향 자동 분류, 각도 계산
    AR/                ARKit 기반 퍼팅 거리 측정 (평면 인식 + hit-testing)
    Trajectory/        공 궤적 탐지 + 탐지 실패 구간 외삽(곡선 피팅)
    Analysis/          기준값 조회, 규칙 기반 피드백 생성, 스윙 점수화
    Storage/
      CoreData/        SwingPro.xcdatamodeld (엔티티 정의), PersistenceController
      PhotoLibrary/    PHAsset 저장/조회
      Repositories/    Core Data ↔ Domain 모델 매핑 (분석 로직은 Domain 모델만 알면 됨)
  Features/            화면별 View + ViewModel (ModeSelection, Practice, Field, Feed, ClipDetail, Settings ...)
  Resources/           Assets.xcassets, Info.plist(XcodeGen 생성), 기준값 시드 JSON
SwingProTests/         순수 로직(점수화/피드백/구간판별/궤적 외삽/촬영방향 분류) 유닛 테스트
docs/requirements.md   원본 요구사양 문서
project.yml            XcodeGen 프로젝트 정의
```

## 현재 구현 상태

로컬 DB 스키마, 도메인 모델, 화면 흐름, 그리고 분석 로직(점수화·피드백·구간 판별·궤적 외삽 등 순수
Swift 알고리즘)은 실제로 동작하도록 작성되어 있고 유닛 테스트로 검증한다. 다만 아래 항목들은
**실기기·Xcode 환경에서만 구현·검증이 가능해 스켈레톤(TODO)으로 남겨두었다**:

- `AVFoundationCameraSession`: 실제 `AVAssetWriter`를 이용한 프리롤 버퍼 + 스윙 구간 파일 기록
- `VisionBallTrajectoryTracker`: 프레임 차분 기반 공 탐지 알고리즘
- `SwingPhaseDetector`의 임계값: 손목 높이 기반 P1~P10 판별 규칙은 베이스라인 로직이며,
  실기기 촬영 데이터로 튜닝이 필요
- `swing_reference_ranges.json`: 체크포인트별 이상적 각도 범위는 초기 추정치(seed data)이며
  전문가 자문/모션캡처 데이터로 보정 필요

`swing_reference_ranges` 테이블은 Core Data 모델에도 정의해 두었지만(요구사양 6장과의 스키마
일치), 실제 런타임 조회는 앱 번들에 포함된 `swing_reference_ranges.json` 시드 데이터를 사용한다
(고정된 상수 데이터라 굳이 가변 DB 테이블로 관리할 필요가 없다고 판단).
