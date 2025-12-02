type Theme = "light" | "dark";

const themeToggle = document.getElementById("themeToggle") as HTMLButtonElement;
const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;

function setTheme(t: Theme) {
  document.documentElement.setAttribute("data-theme", t);
  localStorage.setItem("theme", t);
  themeToggle.textContent = t === "dark" ? "Light mode" : "Dark mode";
}

setTheme((localStorage.getItem("theme") as Theme) || (prefersDark ? "dark" : "light"));
themeToggle?.addEventListener("click", () => {
  const next = (document.documentElement.getAttribute("data-theme") === "dark") ? "light" : "dark";
  setTheme(next as Theme);
});

// Gallery (using placeholder images to avoid external dependencies)
interface Slide {
  src: string;
  caption: string;
}
const slides: Slide[] = [
  { src: "https://upload.wikimedia.org/wikipedia/commons/c/c7/Great_Pyrenees_Mountain_Dog.jpg", caption: "Regal posture and thick double coat." },
  { src: "https://www.borrowmydoggy.com/_next/image?url=https%3A%2F%2Fcdn.sanity.io%2Fimages%2F4ij0poqn%2Fproduction%2F8ab9655c85877976c0d427c4c3a382ae6c9063f8-500x500.png%3Ffit%3Dmax%26auto%3Dformat&w=1080&q=75", caption: "Calm guardians with gentle temperaments." },
  { src: "https://pethelpful.com/.image/w_3840,q_auto:good,c_limit/MjAwMzMyNjg1NTY1MTc1MTYw/great-pyrenees-guide.jpg?arena_f_auto", caption: "Bred to protect livestock in the Pyrenees." }
];

let idx = 0;
const imgEl = document.getElementById("galleryImage") as HTMLImageElement;
imgEl.loading = "lazy";
imgEl.decoding = "async";
const capEl = document.getElementById("galleryCaption") as HTMLElement;
const prevBtn = document.getElementById("prev") as HTMLButtonElement;
const nextBtn = document.getElementById("next") as HTMLButtonElement;

function renderSlide(i: number) {
  const s = slides[i];
  imgEl.src = s.src;
  imgEl.alt = s.caption;
  capEl.textContent = s.caption;
}
renderSlide(idx);

prevBtn?.addEventListener("click", () => {
  idx = (idx - 1 + slides.length) % slides.length;
  renderSlide(idx);
});
nextBtn?.addEventListener("click", () => {
  idx = (idx + 1) % slides.length;
  renderSlide(idx);
});

// Facts rotator
const facts: string[] = [
  "Great Pyrenees were bred as livestock guardians in the Pyrenees Mountains.",
  "They have a weather-resistant double coat that sheds seasonally.",
  "Despite their size, they are typically calm and patient at home.",
  "Early socialization helps balance their independent nature.",
  "They are known for being affectionate with family and good with children."
];

let factIdx = 0;
const factEl = document.getElementById("factText") as HTMLElement;
const nextFactBtn = document.getElementById("nextFact") as HTMLButtonElement;

function showFact(i: number) {
  factEl.textContent = facts[i];
}
showFact(factIdx);

nextFactBtn?.addEventListener("click", () => {
  factIdx = (factIdx + 1) % facts.length;
  showFact(factIdx);
});

// Optional auto-advance
setInterval(() => {
  idx = (idx + 1) % slides.length;
  renderSlide(idx);
}, 6000);