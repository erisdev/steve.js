//@ sourceMappingURL=steve.map
// Generated by CoffeeScript 1.6.1
(function() {
  "use strict";
  var buildModel, camera, draw, getJSON, height, light, renderer, scene, skin, width, _ref;

  THREE.ImageUtils.crossOrigin = '';

  _ref = [480, 640], width = _ref[0], height = _ref[1];

  scene = new THREE.Scene();

  scene.add(new THREE.AmbientLight(0xCCCCCC));

  light = new THREE.PointLight(0xFFFFFF);

  light.position.set(0, 3, 10);

  scene.add(light);

  camera = new THREE.PerspectiveCamera(45, width / height, 1, 100);

  camera.position.set(0, 2, 4);

  camera.lookAt(scene.position);

  renderer = new THREE.WebGLRenderer();

  renderer.setSize(width, height);

  skin = THREE.ImageUtils.loadTexture("data/char.png");

  skin.magFilter = THREE.NearestFilter;

  skin.minFilter = THREE.NearestFilter;

  buildModel = (function() {
    var mapUV, materials, recenter, uRatio, vRatio;
    materials = [
      new THREE.MeshBasicMaterial({
        map: skin,
        side: THREE.DoubleSide,
        transparent: false,
        color: 0xFFFFFF
      }), new THREE.MeshBasicMaterial({
        map: skin,
        side: THREE.DoubleSide,
        transparent: true,
        color: 0xFFFFFF
      })
    ];
    uRatio = 1 / 64;
    vRatio = 1 / 32;
    mapUV = function(box, uv) {
      var face, faceUV, i, u0, u1, v0, v1, _i, _ref1;
      for (face = _i = 0; _i < 6; face = ++_i) {
        i = face * 4;
        _ref1 = uv.slice(i, i + 4), u0 = _ref1[0], v0 = _ref1[1], u1 = _ref1[2], v1 = _ref1[3];
        faceUV = box.faceVertexUvs[0][face];
        faceUV[0].set(u0 * uRatio, v0 * vRatio);
        faceUV[1].set(u0 * uRatio, v1 * vRatio);
        faceUV[2].set(u1 * uRatio, v1 * vRatio);
        faceUV[3].set(u1 * uRatio, v0 * vRatio);
      }
    };
    recenter = function(box, _arg) {
      var matrix, x, y, z;
      x = _arg[0], y = _arg[1], z = _arg[2];
      matrix = new THREE.Matrix4();
      matrix.makeTranslation(-x, -y, -z);
      box.applyMatrix(matrix);
    };
    return function(data) {
      var child, d, geometry, h, part, subdata, w, _i, _len, _ref1, _ref2, _ref3;
      if (data.size) {
        _ref1 = data.size, w = _ref1[0], h = _ref1[1], d = _ref1[2];
        geometry = new THREE.CubeGeometry(w, h, d, 1, 1, 1);
        if (data.anchor != null) {
          recenter(geometry, data.anchor);
        }
        if (data.uv != null) {
          mapUV(geometry, data.uv);
        }
        part = new THREE.Mesh(geometry, materials[+(!!data.transparent)]);
      } else {
        part = new THREE.Object3D();
      }
      if (data.eulerOrder != null) {
        part.eulerOrder = data.eulerOrder;
      }
      if (data.children != null) {
        _ref2 = data.children;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          subdata = _ref2[_i];
          child = buildModel(subdata);
          part.add(child);
        }
      }
      if (data.name != null) {
        part.name = data.name;
      }
      if (data.offset != null) {
        (_ref3 = part.position).set.apply(_ref3, data.offset);
      }
      return part;
    };
  })();

  this.steve = {
    parts: {},
    skin: skin,
    model: (function() {
      var model;
      model = new THREE.Object3D();
      model.scale.set(0.1, 0.1, 0.1);
      scene.add(model);
      return model;
    })(),
    loadSkin: function(url) {
      this.skin.image.src = url;
    }
  };

  draw = function() {
    requestAnimationFrame(draw);
    return renderer.render(scene, camera);
  };

  getJSON = function(url, func) {
    var xhr;
    xhr = new XMLHttpRequest;
    xhr.onreadystatechange = function() {
      var _ref1;
      if (xhr.readyState === xhr.DONE && (200 <= (_ref1 = xhr.status) && _ref1 <= 299)) {
        return func(JSON.parse(xhr.responseText));
      }
    };
    xhr.open('GET', url);
    xhr.send(null);
    return xhr;
  };

  document.addEventListener("DOMContentLoaded", (function(event) {
    getJSON('data/steve.json', function(json) {
      steve.model.add(buildModel(json));
      return typeof steve.attachUI === "function" ? steve.attachUI() : void 0;
    });
    getJSON('skins/skins.json', function(skins) {
      var group, name, opt, url, _i, _len, _ref1;
      if (!(skins.length > 0)) {
        return;
      }
      group = document.createElement('optgroup');
      group.label = 'Preloaded Skins';
      for (_i = 0, _len = skins.length; _i < _len; _i++) {
        _ref1 = skins[_i], name = _ref1.name, url = _ref1.url;
        opt = document.createElement('option');
        opt.value = url;
        opt.textContent = name;
        group.appendChild(opt);
      }
      return document.getElementById('avatar_skin').appendChild(group);
    });
    document.body.appendChild(renderer.domElement);
    return requestAnimationFrame(draw);
  }), false);

}).call(this);
