(function() {
  var html         = document.documentElement;
  var toggleBtns   = document.querySelectorAll('.theme-toggle');
  var menuBtn      = document.getElementById('menu-toggle');
  var menuIconOpen  = document.getElementById('menu-icon-open');
  var menuIconClose = document.getElementById('menu-icon-close');
  var sidebar      = document.getElementById('sidebar');
  var overlay      = document.getElementById('sidebar-overlay');

  // --- Theme ---
  function setTheme(theme) {
    html.dataset.theme = theme;
    try { localStorage.setItem('theme', theme); } catch(e) {}
    var label = theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme';
    toggleBtns.forEach(function(btn) {
      var sun  = btn.querySelector('.theme-icon-sun');
      var moon = btn.querySelector('.theme-icon-moon');
      if (sun)  sun.style.display  = theme === 'dark'  ? 'block' : 'none';
      if (moon) moon.style.display = theme === 'light' ? 'block' : 'none';
      btn.setAttribute('aria-label', label);
    });
  }

  // Sync button state on load
  setTheme(html.dataset.theme || 'light');

  toggleBtns.forEach(function(btn) {
    btn.addEventListener('click', function() {
      setTheme(html.dataset.theme === 'dark' ? 'light' : 'dark');
    });
  });

  // --- Mobile sidebar ---
  function setMenuIcon(open) {
    if (menuIconOpen)  menuIconOpen.style.display  = open ? 'none'  : 'block';
    if (menuIconClose) menuIconClose.style.display = open ? 'block' : 'none';
  }

  function openSidebar() {
    if (!sidebar) return;
    sidebar.classList.add('is-open');
    if (overlay) overlay.classList.add('is-visible');
    if (menuBtn) menuBtn.setAttribute('aria-expanded', 'true');
    setMenuIcon(true);
    document.body.style.overflow = 'hidden';
  }

  function closeSidebar() {
    if (!sidebar) return;
    sidebar.classList.remove('is-open');
    if (overlay) overlay.classList.remove('is-visible');
    if (menuBtn) menuBtn.setAttribute('aria-expanded', 'false');
    setMenuIcon(false);
    document.body.style.overflow = '';
  }

  if (menuBtn) {
    menuBtn.addEventListener('click', function() {
      sidebar.classList.contains('is-open') ? closeSidebar() : openSidebar();
    });
  }

  if (overlay) {
    overlay.addEventListener('click', closeSidebar);
  }

  // Close sidebar on nav link click (mobile)
  if (sidebar) {
    sidebar.querySelectorAll('a').forEach(function(link) {
      link.addEventListener('click', function() {
        if (window.innerWidth < 900) closeSidebar();
      });
    });
  }

  // Close sidebar on Escape
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeSidebar();
  });
})();
