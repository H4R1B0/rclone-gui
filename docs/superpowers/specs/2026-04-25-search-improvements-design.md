# 검색(Search) 개선 — 설계 문서

- **일자**: 2026-04-25
- **브랜치**: `feature/explorer-search-cloud-bookmark-improvements`
- **대상**: Search 영역 (4/4 사이클 중 2번째)
- **선행**: Explorer 사이클 완료 — `SearchViewModel`은 이미 BFS/필터/다중 클라우드를 지원

## 동기

현재 `SearchPanelView`는 결과를 사후 필터링(타입/크기/날짜/경로)하지만:
1. **결과 정렬 불가** — 이름순 고정. 수백~수천 결과에서 크기/수정일로 훑을 수 없음
2. **결과 다중 선택·작업 부재** — 더블클릭으로 폴더 이동만 가능. 검색해서 찾은 파일을 "선택해서 복사/다운로드/삭제"할 수 없음
3. **최근 검색 부재** — 같은 쿼리를 반복 입력. 저장된 검색도 없음

## 범위

### 포함
- **(a) 결과 정렬** — 이름/크기/수정일/리모트 컬럼 클릭 토글
- **(b) 최근 검색 히스토리** — 로컬 저장 최근 10개, 쿼리 입력란 드롭다운

### 제외
- 다중 선택·일괄 작업 (전송 시스템과의 통합 복잡도 큼 — 후속)
- 정규식/글롭, 색인 캐시 — 범위 외

## 아키텍처

- `SearchViewModel.sortField/sortAsc` 추가(Observable). `sortedFilteredResults` 계산 프로퍼티가 `results → 기존 필터 → 정렬` 순.
- `SearchHistoryStore`(신규): UserDefaults에 최근 쿼리 10개 저장. `record(String)`, `recent: [String]`, `clear()`.
- UI: `SearchPanelView`의 결과 테이블 헤더를 클릭 가능한 정렬 버튼으로 교체, 쿼리 입력란에 Menu 드롭다운 추가.

## 영향받는 파일
- `RcloneGUI/ViewModels/SearchViewModel.swift` — `SortField`(검색 로컬) + `sortField/sortAsc`, `sortedFilteredResults` 계산(기존 `filteredResults`를 `SearchPanelView`에서 VM로 이동하는 대신 VM의 순수 데이터 정렬만 담당 → View는 사후 필터 유지)
- `RcloneGUI/ViewModels/SearchHistoryStore.swift` (신규)
- `RcloneGUI/Utilities/AppConstants.swift` — `searchHistoryKey`, `maxSearchHistory`
- `RcloneGUI/Views/SearchPanelView.swift` — 컬럼 정렬, 쿼리 드롭다운
- `RcloneGUI/Utilities/L10n.swift` — 3~4 키
- `RcloneGUITests/SearchViewModelTests.swift` — 정렬/히스토리 테스트

## 구현 순서(커밋 단위)

1. `SearchHistoryStore` + 유닛 테스트 + AppConstants 상수
2. `SearchViewModel`에 정렬 상태 + `performSearch` 훅으로 히스토리 기록
3. `SearchPanelView` 컬럼 정렬 헤더 + 히스토리 드롭다운
4. L10n + 빌드/테스트 검증

## 검증 기준
- [ ] 빌드 경고 0, 전체 테스트 PASS
- [ ] ko/en 문자열 모두 대응
- [ ] 검색 실행 시 히스토리 기록, 중복 시 최상단 이동
- [ ] 컬럼 재클릭 시 정렬 방향 토글
