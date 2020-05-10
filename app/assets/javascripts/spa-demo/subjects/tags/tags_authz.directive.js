(function() {
  "use strict";

  angular
    .module("spa-demo.subjects")
    .directive("sdTagsAuthz", TagsAuthzDirective);

  TagsAuthzDirective.$inject = [];

  function TagsAuthzDirective() {
    var directive = {
        bindToController: true,
        controller: TagsAuthzController,
        controllerAs: "vm",
        restrict: "A",
        link: link
    };
    return directive;

    function link(scope, element, attrs) {
      console.log("TagsAuthzDirective", scope);
    }
  }

  TagsAuthzController.$inject = ["$scope",
                                   "spa-demo.subjects.TagsAuthz"];
  function TagsAuthzController($scope, TagsAuthz) {
    var vm = this;
    vm.authz={};
    vm.authz.canUpdateItem = canUpdateItem;
    vm.newItem=newItem;

    activate();
    return;
    //////////
    function activate() {
      vm.newItem(null);
    }

    function newItem(item) {
      TagsAuthz.getAuthorizedUser().then(
        function(user){ authzUserItem(item, user); },
        function(user){ authzUserItem(item, user); });
    }

    function authzUserItem(item, user) {
      console.log("new Item/Authz", item, user);

      vm.authz.authenticated = TagsAuthz.isAuthenticated();
      vm.authz.canQuery      = TagsAuthz.canQuery();
      vm.authz.canCreate = TagsAuthz.canCreate();
      if (item && item.$promise) {
        vm.authz.canUpdate     = false;
        vm.authz.canDelete     = false;
        vm.authz.canGetDetails = false;
        item.$promise.then(function(){ checkAccess(item); });
      } else {
        checkAccess(item)
      }
    }

    function checkAccess(item) {
      vm.authz.canUpdate     = TagsAuthz.canUpdate(item);
      vm.authz.canDelete     = TagsAuthz.canDelete(item);
      vm.authz.canGetDetails = TagsAuthz.canGetDetails(item);
      console.log("checkAccess", item, vm.authz);
    }

    function canUpdateItem(item) {
      return TagsAuthz.canUpdate(item);
    }
  }
})();
