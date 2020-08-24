local handler = require("event_handler")
handler.add_lib(require("modules.extra_starting_items")) --최초/부활 지급품 변경
handler.add_lib(require("modules.antipollution")) --공해싫어요
handler.add_lib(require("modules.revenge_tree")) --나무가 반격함
handler.add_lib(require("modules.no_base_on_resource")) --광물위에 기지좀 짓지마
handler.add_lib(require("modules.corpse_marker")) --뒤지면 마커를 남겨줄게
handler.add_lib(require("modules.mini_bonus")) --조그만 상시 이동속도 보너스
handler.add_lib(require("modules.hate_landfill")) --매립 싫어요
handler.add_lib(require("silo-script")) --바닐라 프리플레이 로켓발사통계 버튼
