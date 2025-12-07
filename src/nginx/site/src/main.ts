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

const imgEl = document.getElementById("galleryImage") as HTMLImageElement;
imgEl.loading = "lazy";
imgEl.decoding = "async";
const capEl = document.getElementById("galleryCaption") as HTMLElement;
const prevBtn = document.getElementById("prev") as HTMLButtonElement;
const nextBtn = document.getElementById("next") as HTMLButtonElement;

interface DogApiResponse {
  message: string;
  status: string;
}

const dogHistory: string[] = [];
let currentDogIndex = -1;

async function fetchRandomDog() {
  try {
    nextBtn.disabled = true;
    capEl.textContent = "Fetching a new friend...";
    
    const res = await fetch("https://dog.ceo/api/breeds/image/random");
    const data: DogApiResponse = await res.json();
    
    if (data.status === "success") {
      dogHistory.push(data.message);
      currentDogIndex = dogHistory.length - 1;
      renderDog();
    } else {
      capEl.textContent = "Failed to load dog image.";
    }
  } catch (e) {
    console.error(e);
    capEl.textContent = "Error connecting to Dog API.";
  } finally {
    nextBtn.disabled = false;
  }
}

function renderDog() {
  if (currentDogIndex >= 0 && currentDogIndex < dogHistory.length) {
    imgEl.src = dogHistory[currentDogIndex];
    imgEl.alt = "Random Dog";
    capEl.textContent = `Random Dog #${currentDogIndex + 1}`;
    prevBtn.disabled = currentDogIndex === 0;
  }
}

fetchRandomDog();

prevBtn?.addEventListener("click", () => {
  if (currentDogIndex > 0) {
    currentDogIndex--;
    renderDog();
  }
});

nextBtn?.addEventListener("click", () => {
  if (currentDogIndex < dogHistory.length - 1) {
    currentDogIndex++;
    renderDog();
  } else {
    fetchRandomDog();
  }
});