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
  const videoBaseUrl = "https://ckvideos.atl1.cdn.digitaloceanspaces.com/";

  const buildVideoUrl = (sourceFileName) => {
    if (!sourceFileName) {
      return null;
    }
    const encodedName = encodeURIComponent(sourceFileName);
    return `${videoBaseUrl}${encodedName}`;
  };

  const overlay = document.createElement("div");
  overlay.className = "video-lightbox-overlay";
  overlay.innerHTML = `
    <div class="video-lightbox" role="dialog" aria-modal="true" aria-label="Video player">
      <button type="button" class="video-lightbox-close" aria-label="Close">×</button>
      <video controls preload="metadata"></video>
    </div>
  `;
  document.body.appendChild(overlay);

  const lightbox = overlay.querySelector(".video-lightbox");
  const videoElement = overlay.querySelector("video");
  const closeButton = overlay.querySelector(".video-lightbox-close");

  const closeLightbox = () => {
    overlay.classList.remove("is-open");
    if (videoElement) {
      videoElement.pause();
      videoElement.removeAttribute("src");
      videoElement.load();
    }
  };

  const openLightbox = (sourceFileName, vimeoId, name) => {
    const url = buildVideoUrl(sourceFileName);
    if (!url || !videoElement) {
      return;
    }
    if (vimeoId) {
      const posterUrl = `/video/thumbnails/${vimeoId}.png`;
      videoElement.setAttribute("poster", posterUrl);
    } else {
      videoElement.removeAttribute("poster");
    }
    videoElement.src = url;
    videoElement.load();
    overlay.classList.add("is-open");
  };

  if (closeButton) {
    closeButton.addEventListener("click", closeLightbox);
  }

  overlay.addEventListener("click", (event) => {
    if (event.target === overlay) {
      closeLightbox();
    }
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      closeLightbox();
    }
  });

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

      const sourceFileName = video?.source_file_name;

      const wrapper = document.createElement("div");
      wrapper.className = "video-thumb";

      const thumbButton = document.createElement("button");
      thumbButton.type = "button";
      thumbButton.className = "video-thumb-button";

      const img = document.createElement("img");
      img.loading = "lazy";
      img.alt = video?.name ? video.name : `Vimeo ${vimeoId}`;
      img.src = `/video/thumbnails/${vimeoId}.png`;
      img.onerror = () => {
        img.remove();
      };

      thumbButton.appendChild(img);
      thumbButton.addEventListener("click", () => openLightbox(sourceFileName, vimeoId, video?.name));

      const meta = document.createElement("div");
      meta.className = "video-meta";

      const titleButton = document.createElement("button");
      titleButton.type = "button";
      titleButton.className = "video-thumb-button video-title";
      titleButton.textContent = video?.name || `Vimeo ${vimeoId}`;
      titleButton.addEventListener("click", () => openLightbox(sourceFileName, vimeoId, video?.name));

      const vimeoLink = document.createElement("a");
      vimeoLink.className = "video-vimeo";
      vimeoLink.href = `https://vimeo.com/video/${vimeoId}`;
      vimeoLink.target = "_blank";
      vimeoLink.rel = "noopener";
      vimeoLink.title = "Open on Vimeo";

      const vimeoIcon = document.createElement("img");
      vimeoIcon.alt = "Vimeo";
      vimeoIcon.src = "/img/icons/vimeo.png";

      vimeoLink.appendChild(vimeoIcon);
      meta.appendChild(titleButton);
      meta.appendChild(vimeoLink);

      wrapper.appendChild(thumbButton);
      wrapper.appendChild(meta);
      fragment.appendChild(wrapper);
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
