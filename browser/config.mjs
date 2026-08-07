const TITLE = "Planet Labs - Open Data";

/**
 * Planet open-data overlay for radiant STAC Browser.
 * Merged via SB_CONFIG on top of upstream config.js.
 * pathPrefix / catalogUrl / catalogImage are set by the Makefile via SB_* env vars.
 */
export default {
  catalogTitle: TITLE,
  // Logo already contains the Planet wordmark; keep document title via catalogTitle.
  catalogTitleAfterImage: "",
  allowExternalAccess: true,
  historyMode: "history",
  preprocessSTAC: (stac) => {
    if (stac.id === "planet") {
      stac.title = TITLE;
    }
    return stac;
  },
};
