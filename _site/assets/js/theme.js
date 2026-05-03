(function() {
  var html    = document.documentElement;
  var lightBtn = document.querySelector('[data-theme-value="light"]');
  var darkBtn  = document.querySelector('[data-theme-value="dark"]');
  var menuBtn  = document.getElementById('menu-toggle');
  var sidebar  = document.getElementById('sidebar');
  var overlay  = document.getElementById('sidebar-overlay');

  // --- Theme ---
  function setTheme(theme) {
    html.dataset.theme = theme;
    try { localStorage.setItem('theme', theme); } catch(e) {}
    if (lightBtn) lightBtn.setAttribute('aria-pressed', theme === 'light' ? 'true' : 'false');
    if (darkBtn)  darkBtn.setAttribute('aria-pressed', theme === 'dark'  ? 'true' : 'false');
  }

  // Sync button state on load
  setTheme(html.dataset.theme || 'light');

  if (lightBtn) lightBtn.addEventListener('click', function() { setTheme('light'); });
  if (darkBtn)  darkBtn.addEventListener('click', function() { setTheme('dark'); });

  // --- Mobile sidebar ---
  function openSidebar() {
    if (!sidebar) return;
    sidebar.classList.add('is-open');
    if (overlay) overlay.classList.add('is-visible');
    if (menuBtn) menuBtn.setAttribute('aria-expanded', 'true');
    document.body.style.overflow = 'hidden';
  }

  function closeSidebar() {
    if (!sidebar) return;
    sidebar.classList.remove('is-open');
    if (overlay) overlay.classList.remove('is-visible');
    if (menuBtn) menuBtn.setAttribute('aria-expanded', 'false');
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
