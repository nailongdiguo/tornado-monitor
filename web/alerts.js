/* 龙卷风 / 强对流 实时弹窗预警（中英双语） */
(function () {
  var LS = "tornado_seen_v2";
  var SEV_ZH = { "Grande Perigo": "红色警报", "Perigo": "橙色警报" };
  var SEV_EN = { "Grande Perigo": "Red Alert", "Perigo": "Orange Alert" };
  var SEV_COLOR = { "Grande Perigo": "#ff2d2d", "Perigo": "#ff8a00", "Extreme": "#ff2d2d", "Severe": "#ff8a00" };

  function seen() { try { return JSON.parse(localStorage.getItem(LS) || "[]"); } catch (e) { return []; } }
  function saveSeen(a) { try { localStorage.setItem(LS, JSON.stringify(a.slice(-300))); } catch (e) {} }
  function fmt(t) {
    if (!t) return "—";
    try { var d = new Date(t); if (isNaN(d.getTime())) return t;
      return d.toLocaleString("zh-CN", { month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit" }); }
    catch (e) { return t; }
  }
  function esc(s) { return String(s == null ? "" : s).replace(/[&<>"]/g, function (c) { return ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]; }); }

  // 注入样式
  var st = document.createElement("style");
  st.textContent = [
    "#al-bar{position:fixed;right:12px;bottom:12px;z-index:9998;background:#1b2b3f;border:1px solid #33475f;",
    "border-radius:10px;padding:8px 12px;color:#e6edf3;font:13px/1.4 -apple-system,sans-serif;cursor:pointer;",
    "box-shadow:0 4px 16px rgba(0,0,0,.5)}",
    "#al-bar b{color:#ff5038}",
    "#al-mask{position:fixed;inset:0;background:rgba(0,0,0,.72);z-index:9999;display:none;align-items:center;justify-content:center;padding:16px}",
    "#al-card{max-width:520px;width:100%;background:#0f1720;border:2px solid #ff2d2d;border-radius:14px;padding:18px;",
    "color:#e6edf3;font-family:-apple-system,sans-serif;box-shadow:0 10px 40px rgba(0,0,0,.8);animation:alIn .25s ease}",
    "@keyframes alIn{from{transform:scale(.94);opacity:0}to{transform:scale(1);opacity:1}}",
    "#al-card h3{margin:0 0 4px;font-size:19px;color:#ff5038}",
    "#al-card .en{color:#8fa3b8;font-size:13px;margin-bottom:10px}",
    "#al-card .row{margin:6px 0;font-size:14px}",
    "#al-card .k{color:#8fa3b8;margin-right:6px}",
    "#al-card button{margin-top:14px;width:100%;padding:10px;background:#ff5038;border:0;border-radius:8px;",
    "color:#fff;font-size:15px;cursor:pointer}"
  ].join("");
  document.head.appendChild(st);

  var bar = document.createElement("div");
  bar.id = "al-bar";
  bar.innerHTML = "🌪 预警加载中…";
  bar.onclick = function () { render(true); };
  document.body.appendChild(bar);

  var mask = document.createElement("div");
  mask.id = "al-mask";
  mask.innerHTML = '<div id="al-card"></div>';
  mask.onclick = function (e) { if (e.target === mask) mask.style.display = "none"; };
  document.body.appendChild(mask);

  var cache = [];
  function render(openAll) {
    var n = cache.length;
    bar.innerHTML = n ? ('🌪 <b>' + n + "</b> 条活跃预警 / active alerts") : "🌪 暂无活跃预警 · no active alerts";
    if (openAll && n) show(cache[0]);
  }
  function show(a) {
    var isUS = a.source === "US";
    var tzh = isUS ? "美国龙卷风预警" : "巴西强对流警报";
    var ten = isUS ? "Tornado Warning (US)" : "Brazil Severe Weather Alert";
    var lvzh = isUS ? (a.severity || "警报") : (SEV_ZH[a.severity] || a.severity || "警报");
    var lven = isUS ? (a.severity || "Alert") : (SEV_EN[a.severity] || a.severity || "Alert");
    var html = "<h3>" + (isUS ? "🇺🇸 " : "🇧🇷 ") + tzh + "</h3><div class='en'>" + ten + "</div>" +
      "<div class='row'><span class='k'>地区 Area</span>" + esc(a.area) + "</div>" +
      "<div class='row'><span class='k'>等级 Level</span>" + esc(lvzh) + " / " + esc(lven) + "</div>" +
      "<div class='row'><span class='k'>生效 Until</span>" + esc(fmt(a.end)) + "</div>" +
      "<div class='row' style='color:#8fa3b8;font-size:12px;margin-top:10px'>" +
      (isUS ? "请立即寻求坚固建筑避险。Take shelter now." : "注意强风、冰雹与暴雨。Beware wind, hail and heavy rain.") + "</div>" +
      "<button onclick=\"document.getElementById('al-mask').style.display='none'\">关闭 Close</button>";
    document.getElementById("al-card").innerHTML = html;
    mask.style.display = "flex";
    try { var ctx = new (window.AudioContext || window.webkitAudioContext)(); var o = ctx.createOscillator();
      o.type = "square"; o.frequency.value = isUS ? 880 : 600; o.connect(ctx.destination); o.start();
      setTimeout(function () { o.stop(); }, 220); } catch (e) {}
    if (window.Notification && Notification.permission === "granted") {
      try { new Notification(tzh + " / " + ten, { body: a.area + " — " + tzh, tag: a.id }); } catch (e) {}
    }
  }
  function tick() {
    fetch("alerts.json?_=" + Date.now(), { cache: "no-store" })
      .then(function (r) { return r.json(); })
      .then(function (d) {
        cache = (d && d.alerts) || [];
        render(false);
        var s = seen(), fresh = [];
        cache.forEach(function (a) { if (s.indexOf(a.id) < 0) fresh.push(a); });
        if (fresh.length) {
          fresh.slice(0, 3).forEach(function (a) { show(a); });
          s = s.concat(fresh.map(function (a) { return a.id; }));
          saveSeen(s);
        }
      })
      .catch(function () {});
  }
  if (window.Notification && Notification.permission === "default") { try { Notification.requestPermission(); } catch (e) {} }
  tick(); setInterval(tick, 60000);
})();
