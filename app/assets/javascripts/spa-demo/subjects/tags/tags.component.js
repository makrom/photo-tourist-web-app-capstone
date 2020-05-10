(function() {
  "use strict";

  angular
    .module("spa-demo.subjects")
    .component("sdTagSelector", {
      templateUrl: tagSelectorTemplateUrl,
      controller: TagSelectorController,
      bindings: {
        authz: "<"
      },
    })
    .component("sdTagEditor", {
      templateUrl: tagEditorTemplateUrl,
      controller: TagEditorController,
      bindings: {
        authz: "<"
      },
      require: {
        tagsAuthz: "^sdTagsAuthz"
      }
    });


  tagSelectorTemplateUrl.$inject = ["spa-demo.config.APP_CONFIG"];
  function tagSelectorTemplateUrl(APP_CONFIG) {
    return APP_CONFIG.tag_selector_html;
  }
  tagEditorTemplateUrl.$inject = ["spa-demo.config.APP_CONFIG"];
  function tagEditorTemplateUrl(APP_CONFIG) {
    return APP_CONFIG.tag_editor_html;
  }

  TagSelectorController.$inject = ["$scope",
                                   "$stateParams",
                                   "spa-demo.authz.Authz",
                                   "spa-demo.subjects.Tag"];
  function TagSelectorController($scope, $stateParams, Authz, Tag) {
    var vm=this;

    vm.$onInit = function() {
      console.log("TagSelectorController",$scope);
      $scope.$watch(function(){ return Authz.getAuthorizedUserId(); },
                    function(){
                      if (!$stateParams.id) {
                        vm.items = Tag.query();
                      }
                    });
    }
    return;
    //////////////
  }


  TagEditorController.$inject = ["$scope","$q",
                                 "$state", "$stateParams",
                                 "spa-demo.authz.Authz",
                                 "spa-demo.subjects.Tag",
                                 "spa-demo.subjects.TagThing",
                                 "spa-demo.subjects.TagLinkableThing",
                                 ];
  function TagEditorController($scope, $q, $state, $stateParams,
                                 Authz, Tag, TagThing,TagLinkableThing) {
    var vm=this;
    vm.selected_linkables=[];
    vm.create = create;
    vm.clear  = clear;
    vm.update  = update;
    vm.remove  = remove;
    vm.linkThings = linkThings;

    vm.$onInit = function() {
      console.log("TagEditorController",$scope);
      $scope.$watch(function(){ return Authz.getAuthorizedUserId(); },
                    function(){
                      if ($stateParams.id) {
                        reload($stateParams.id);
                      } else {
                        newResource();
                      }
                    });
    }
    return;
    //////////////
    function newResource() {
      console.log("newResource()");
      vm.item = new Tag();
      vm.tagsAuthz.newItem(vm.item);
      return vm.item;
    }

    function reload(tagId) {
      var itemId = tagId ? tagId : vm.item.id;
      console.log("re/loading tag", itemId);
      vm.item = Tag.get({id:itemId});
      vm.things = TagThing.query({tag_id:itemId});
      vm.linkable_things = TagLinkableThing.query({tag_id:itemId});
      vm.tagsAuthz.newItem(vm.item);
      $q.all([vm.item.$promise,
              vm.things.$promise]).catch(handleError);
    }

    function clear() {
      newResource();
      $state.go(".", {id:null});
    }

    function create() {
      vm.item.$save().then(
        function(){
           $state.go(".", {id: vm.item.id});
        },
        handleError);
    }

    function update() {
      vm.item.errors = null;
      var update=vm.item.$update();
      linkThings(update);
    }

    function linkThings(parentPromise) {
      var promises=[];
      if (parentPromise) { promises.push(parentPromise); }
      angular.forEach(vm.selected_linkables, function(linkable){
        var resource=TagThing.save({tag_id:vm.item.id}, {thing_id:linkable});
        promises.push(resource.$promise);
      });

      vm.selected_linkables=[];
      console.log("waiting for promises", promises);
      $q.all(promises).then(
        function(response){
          console.log("promise.all response", response);
          $scope.tagform.$setPristine();
          reload();
        },
        handleError);
    }

    function remove() {
      vm.item.errors = null;
      vm.item.$delete().then(
        function(){
          console.log("remove complete", vm.item);
          clear();
        },
        handleError);
    }


    function handleError(response) {
      console.log("error", response);
      if (response.data) {
        vm.item["errors"]=response.data.errors;
      }
      if (!vm.item.errors) {
        vm.item["errors"]={}
        vm.item["errors"]["full_messages"]=[response];
      }
      $scope.tagform.$setPristine();
    }
  }

})();
