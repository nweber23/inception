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

function showSecret(): void {
  imgEl.src = "assets/fish-spin-sha.gif";
  imgEl.alt = "Secret";
  capEl.textContent = "You found the secret!";
}

function renderDog() {
  if (currentDogIndex >= 0 && currentDogIndex < dogHistory.length) {
    imgEl.src = dogHistory[currentDogIndex];
    imgEl.alt = "Random Dog";
    capEl.textContent = `Random Dog #${currentDogIndex + 1}`;
    // Keep Prev enabled so users can try to go before the first image (to trigger the secret)
    prevBtn.disabled = dogHistory.length === 0;
  }
}

fetchRandomDog();

prevBtn?.addEventListener("click", () => {
  if (currentDogIndex > 0) {
    currentDogIndex--;
    renderDog();
  } else {
    // Trying to go to a negative amount of dog -> show the easter egg GIF
    showSecret();
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