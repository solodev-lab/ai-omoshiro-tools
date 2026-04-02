/* ===== Solara 5-Tab Navigation ===== */
(function() {
  const TABS = [
    { id: 'map',       icon: '🧭', label: 'Map',       href: 'index.html' },
    { id: 'horo',      icon: '🌀', label: 'Horo',      href: 'horoscope.html' },
    { id: 'tarot',     icon: '✨', label: 'Tarot',     href: 'tarot.html' },
    { id: 'galaxy',    icon: '🌌', label: 'Galaxy',    href: 'galaxy.html' },
    { id: 'sanctuary', icon: '🏛', label: 'Sanctuary', href: 'sanctuary.html' },
  ];

  /**
   * Render the 5-tab bottom navigation bar.
   * Call from each page: renderNav('map') / renderNav('horo') / etc.
   */
  window.renderNav = function(activeTab) {
    const nav = document.querySelector('.bottom-nav');
    if (!nav) return;
    nav.innerHTML = TABS.map(t => {
      const cls = t.id === activeTab ? 'nav-item active' : 'nav-item';
      const click = t.id === activeTab ? '' : `onclick="location.href='${t.href}'"`;
      return `<div class="${cls}" ${click}><div class="nav-icon">${t.icon}</div><div class="nav-label">${t.label}</div></div>`;
    }).join('');
  };
})();
