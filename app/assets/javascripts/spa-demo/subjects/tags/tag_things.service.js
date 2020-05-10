(function() {
  "use strict";

  angular
    .module("spa-demo.subjects")
    .factory("spa-demo.subjects.TagThing", TagThing);

  TagThing.$inject = ["$resource", "spa-demo.config.APP_CONFIG"];
  function TagThing($resource, APP_CONFIG) {
    return $resource(APP_CONFIG.server_url + "/api/tags/:tag_id/thing_tags");
  }

})();
