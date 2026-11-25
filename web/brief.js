/* 每日简报：页面常驻卡片（不弹窗），中英双语，美国+巴西 */
(function () {
  var sec = document.getElementById("brief");
  if (!sec) return;
  var body = document.getElementById("brief-b");
  var tog = document.getElementById("brief-t");
  var head = document.getElementById("brief-h");
  var open = true;
  head.onclick = function () {
    open = !open;
    body.style.display = open ? "block" : "none";
    tog.textContent = open ? "收起 ▴" : "展开 ▾";
  };
  function load() {
    fetch("brief.json?_=" + Date.now(), { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        body.innerHTML = d.zh + "<br><br><span style='color:#9fb3c8;font-size:12.5px'>" + d.en + "</span>" +
          "<br><span style='color:#6b7f94;font-size:11.5px'>更新于 " + (d.updated || "") + "</span>";
      })
      .catch(function () { body.textContent = "简报加载失败 / brief unavailable"; });
  }
  load();
  setInterval(load, 300000); // 5 分钟刷新
})();
