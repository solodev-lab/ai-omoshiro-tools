/* ===== Solara 5-Tab Navigation ===== */
(function() {
  const TABS = [
    { id: 'map',       icon: 'map',       label: 'Map',       href: 'index.html' },
    { id: 'horo',      icon: 'horo',      label: 'Horo',      href: 'horoscope.html' },
    { id: 'tarot',     icon: 'tarot',     label: 'Tarot',     href: 'tarot.html' },
    { id: 'galaxy',    icon: 'galaxy',    label: 'Galaxy',    href: 'galaxy.html' },
    { id: 'sanctuary', icon: 'sanctuary', label: 'Sanctuary', href: 'sanctuary.html' },
  ];

  /**
   * Render the 5-tab bottom navigation bar.
   * Call from each page: renderNav('map') / renderNav('horo') / etc.
   */
  window.renderNav = function(activeTab) {
    const nav = document.querySelector('.bottom-nav');
    if (!nav) return;
    const icons = window.SOLARA_ICONS || {};
    nav.innerHTML = TABS.map(t => {
      const cls = t.id === activeTab ? 'nav-item active' : 'nav-item';
      const click = t.id === activeTab ? '' : `onclick="location.href='${t.href}'"`;
      const iconHtml = icons[t.icon] || t.icon;
      return `<div class="${cls}" ${click}><div class="nav-icon">${iconHtml}</div><div class="nav-label">${t.label}</div></div>`;
    }).join('');
  };
})();
