(function() {
  "use strict";

  angular
    .module("spa-demo.subjects")
    .factory("spa-demo.subjects.ThingTag", ThingTag);

  ThingTag.$inject = ["$resource", "spa-demo.config.APP_CONFIG"];
  function ThingTag($resource, APP_CONFIG) {
    return $resource(APP_CONFIG.server_url + "/api/things/:thing_id/thing_tags/:id",
      { thing_id: '@thing_id',
        id: '@id'},
      { update: {method:"PUT"}
      });
  }

})();
