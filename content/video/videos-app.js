(() => {
  const PAGE_SIZE = 20;
  const gallery = document.getElementById("video-gallery");
  const prevButton = document.getElementById("video-prev");
  const nextButton = document.getElementById("video-next");
  const pageNumbers = document.getElementById("video-page-numbers");

  if (!gallery || !prevButton || !nextButton || !pageNumbers) {
    return;
  }

  let videos = [];
  let currentPage = 1;

  const clampPage = (page, totalPages) => {
    if (totalPages <= 0) {
      return 1;
    }
    return Math.min(Math.max(1, page), totalPages);
  };

  const setPageInUrl = (page) => {
    const url = new URL(window.location.href);
    url.searchParams.set("page", String(page));
    window.history.replaceState({}, "", url);
  };

  const updateButtons = (totalPages) => {
    prevButton.disabled = currentPage <= 1;
    nextButton.disabled = currentPage >= totalPages;

    pageNumbers.innerHTML = "";
    if (totalPages === 0) {
      return;
    }

    const fragment = document.createDocumentFragment();
    for (let page = 1; page <= totalPages; page += 1) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = page === currentPage
        ? "btn btn-secondary btn-sm"
        : "btn btn-outline-secondary btn-sm";
      button.dataset.page = String(page);
      button.textContent = String(page);
      fragment.appendChild(button);
    }

    pageNumbers.appendChild(fragment);
  };

  const renderPage = () => {
    const totalPages = Math.ceil(videos.length / PAGE_SIZE);
    currentPage = clampPage(currentPage, totalPages);

    gallery.innerHTML = "";

    if (videos.length === 0) {
      gallery.textContent = "No videos found.";
      updateButtons(0);
      return;
    }

    const start = (currentPage - 1) * PAGE_SIZE;
    const end = start + PAGE_SIZE;
    const pageVideos = videos.slice(start, end);

    const fragment = document.createDocumentFragment();
    pageVideos.forEach((video) => {
      const vimeoId = video?.vimeo_id;
      if (!vimeoId) {
        return;
      }

      const link = document.createElement("a");
      link.className = "video-thumb";
      link.href = `https://vimeo.com/video/${vimeoId}`;
      link.target = "_blank";
      link.rel = "noopener";

      const img = document.createElement("img");
      img.loading = "lazy";
      img.alt = video?.name ? video.name : `Vimeo ${vimeoId}`;
      img.src = `/video/thumbnails/${vimeoId}.png`;
      img.onerror = () => {
        img.remove();
      };

      const title = document.createElement("div");
      title.className = "video-title";
      title.textContent = video?.name || `Vimeo ${vimeoId}`;

      link.appendChild(img);
      link.appendChild(title);
      fragment.appendChild(link);
    });

    gallery.appendChild(fragment);
    updateButtons(totalPages);
    if (totalPages > 0) {
      setPageInUrl(currentPage);
    }
  };

  prevButton.addEventListener("click", () => {
    if (currentPage > 1) {
      currentPage -= 1;
      renderPage();
    }
  });

  nextButton.addEventListener("click", () => {
    const totalPages = Math.ceil(videos.length / PAGE_SIZE);
    if (currentPage < totalPages) {
      currentPage += 1;
      renderPage();
    }
  });

  pageNumbers.addEventListener("click", (event) => {
    const target = event.target;
    if (!(target instanceof HTMLButtonElement)) {
      return;
    }
    const page = Number(target.dataset.page);
    if (!Number.isNaN(page) && page >= 1) {
      currentPage = page;
      renderPage();
    }
  });

  fetch("/video/videos.json")
    .then((response) => {
      if (!response.ok) {
        throw new Error("Failed to load videos");
      }
      return response.json();
    })
    .then((data) => {
      videos = Array.isArray(data) ? data : [];
      const totalPages = Math.ceil(videos.length / PAGE_SIZE);
      const urlPage = Number(new URL(window.location.href).searchParams.get("page"));
      if (!Number.isNaN(urlPage)) {
        currentPage = clampPage(urlPage, totalPages);
      }
      renderPage();
    })
    .catch(() => {
      gallery.textContent = "Failed to load videos.";
    });
})();
