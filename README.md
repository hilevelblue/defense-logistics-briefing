# 국방 물류·군수 AI 데일리 브리핑

매일 아침 클라우드 에이전트(Claude Code routine)가 국방 물류·군수 AI 동향을 조사합니다. 조사 결과는 A4 가로 인포그래픽으로 만들어 `briefings/YYYY-MM-DD.{png,pdf,html}`에 저장하고 메일로 보냅니다.

- `template.html`: 인포그래픽 템플릿입니다. `/*DATA_START*/ … /*DATA_END*/` 사이에 데이터가 들어갑니다.
- `render.sh`: `bash render.sh data.json`을 실행하면 PNG(2246×1588)와 PDF(A4 가로)가 만들어집니다.

## data.json 형식
```json
{
  "issue": "제N호", "date": "2026. 10. 18. (일)", "period": "2026. 10. 16. ~ 10. 18.",
  "slogan": "상단 우측 문구", "title": "한눈에 보는 국방 물류·군수 AI 동향", "subtitle": "오늘의 한 줄 메시지",
  "cards": [  // 정확히 5개, 카드당 items 1~4개
    {"title": "카드 제목(10자 내외)", "sub": "부제(20자 내외)", "art": "drones",
     "items": [{"h": "제목(28자 이내)", "d": "설명(34자 이내)", "s": "출처 · 날짜"}]}
  ],
  "implications": [{"tag": "획득", "h": "시사점(24자 이내)", "d": "부연(30자 이내)"}],  // 3~5개
  "messages": ["핵심 메시지 4개(각 18자 이내)"],
  "footer": "출처·주석 한 줄"
}
```
`art`에 쓸 수 있는 값: `drones`(자율·무인), `dashboard`(예측·데이터), `airlift`(수송·경합군수), `network`(공급망), `korea`(한국), `maintenance`(정비), `contract`(계약·투자), `policy`(정책), `cyber`(보안), `ship`(해군·해상)
