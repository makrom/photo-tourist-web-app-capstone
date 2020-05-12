(function() {
  "use strict";

  angular
    .module("spa-demo.subjects")
    .factory("spa-demo.subjects.TagLinkableThing", TagLinkableThing);

  TagLinkableThing.$inject = ["$resource", "spa-demo.config.APP_CONFIG"];
  function TagLinkableThing($resource, APP_CONFIG) {
    return $resource(APP_CONFIG.server_url + "/api/tags/:tag_id/linkable_things");
  }

})();
