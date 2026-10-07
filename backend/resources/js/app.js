// Mobile menu
const menu = document.querySelector('[data-menu]');
document.querySelectorAll('[data-menu-toggle]').forEach((btn) =>
    btn.addEventListener('click', () => {
        const open = menu.classList.toggle('hidden') === false;
        document.body.classList.toggle('overflow-hidden', open);
        btn.setAttribute('aria-expanded', String(open));
    }),
);
menu?.querySelectorAll('a').forEach((a) =>
    a.addEventListener('click', () => {
        menu.classList.add('hidden');
        document.body.classList.remove('overflow-hidden');
    }),
);

// Nav gets a surface once the page scrolls.
const nav = document.querySelector('[data-nav]');
const onScroll = () => nav?.classList.toggle('is-scrolled', window.scrollY > 12);
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

// Fade sections in as they enter the viewport.
const io = new IntersectionObserver(
    (entries) => entries.forEach((e) => {
        if (e.isIntersecting) {
            e.target.classList.add('is-in');
            io.unobserve(e.target);
        }
    }),
    { threshold: 0.12, rootMargin: '0px 0px -40px 0px' },
);
document.querySelectorAll('.reveal').forEach((el) => io.observe(el));

// Screenshot rail arrows.
document.querySelectorAll('[data-rail]').forEach((rail) => {
    const scroll = (dir) => rail.scrollBy({ left: dir * Math.min(rail.clientWidth * 0.8, 640), behavior: 'smooth' });
    document.querySelector(`[data-rail-prev="${rail.dataset.rail}"]`)?.addEventListener('click', () => scroll(-1));
    document.querySelector(`[data-rail-next="${rail.dataset.rail}"]`)?.addEventListener('click', () => scroll(1));
});

// Count-up numbers.
const fmt = (n, bn) => {
    const s = Math.round(n).toLocaleString('en-IN');
    return bn ? s.replace(/\d/g, (d) => '০১২৩৪৫৬৭৮৯'[d]) : s;
};
const counters = new IntersectionObserver((entries) => entries.forEach((e) => {
    if (!e.isIntersecting) return;
    const el = e.target;
    const to = Number(el.dataset.count);
    const bn = el.dataset.bn === '1';
    const start = performance.now();
    const tick = (t) => {
        const p = Math.min(1, (t - start) / 1200);
        el.textContent = (el.dataset.prefix || '') + fmt(to * (1 - Math.pow(1 - p, 3)), bn);
        if (p < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
    counters.unobserve(el);
}), { threshold: 0.6 });
document.querySelectorAll('[data-count]').forEach((el) => counters.observe(el));

// Show / hide password on the login page.
document.querySelectorAll('[data-reveal-password]').forEach((btn) =>
    btn.addEventListener('click', () => {
        const input = document.getElementById(btn.dataset.revealPassword);
        const show = input.type === 'password';
        input.type = show ? 'text' : 'password';
        btn.querySelector('.ms').textContent = show ? 'visibility_off' : 'visibility';
    }),
);
