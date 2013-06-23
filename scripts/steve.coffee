"use strict"

THREE.ImageUtils.crossOrigin = ''

[width, height] = [480, 640]

scene = new THREE.Scene()
scene.add new THREE.AmbientLight(0xCCCCCC)

light = new THREE.PointLight(0xFFFFFF)
light.position.set 0, 3, 10
scene.add light

camera = new THREE.PerspectiveCamera(45, width / height, 1, 100)
camera.position.set 0, 2, 4
camera.lookAt scene.position

renderer = new THREE.WebGLRenderer()
renderer.setSize width, height

skin = THREE.ImageUtils.loadTexture("data/char.png")
skin.magFilter = THREE.NearestFilter
skin.minFilter = THREE.NearestFilter

buildModel = do ->
  materials = [
    new THREE.MeshBasicMaterial
      map: skin
      side: THREE.DoubleSide
      transparent: false
      color: 0xFFFFFF
    new THREE.MeshBasicMaterial
      map: skin
      side: THREE.DoubleSide
      transparent: true
      color: 0xFFFFFF
  ]
  
  uRatio = 1 / 64
  vRatio = 1 / 32
  
  mapUV = (box, uv) ->
    for face in [0...6]
      i = face * 4
      [u0, v0, u1, v1] = uv.slice(i, i + 4)
      
      faceUV = box.faceVertexUvs[0][face]
      faceUV[0].set u0 * uRatio, v0 * vRatio
      faceUV[1].set u0 * uRatio, v1 * vRatio
      faceUV[2].set u1 * uRatio, v1 * vRatio
      faceUV[3].set u1 * uRatio, v0 * vRatio
    return
  
  recenter = (box, [x, y, z]) ->
    matrix = new THREE.Matrix4()
    matrix.makeTranslation -x, -y, -z
    box.applyMatrix matrix
    return
  
  (data) ->
    if data.size
      [w, h, d] = data.size
      geometry = new THREE.CubeGeometry w, h, d, 1, 1, 1
      recenter geometry, data.anchor if data.anchor?
      mapUV geometry, data.uv if data.uv?
      part = new THREE.Mesh(geometry, materials[+!!data.transparent])
    else
      part = new THREE.Object3D()
    
    part.eulerOrder = data.eulerOrder if data.eulerOrder?
    
    if data.children?
      for subdata in data.children
        child = buildModel subdata
        part.add child
    
    part.name = data.name if data.name?
    part.position.set data.offset... if data.offset?
    part

@steve =
  parts: {}
  skin: skin
  model: do ->
    model = new THREE.Object3D()
    model.scale.set 0.1, 0.1, 0.1
    scene.add model
    model
  
  loadSkin: (url) ->
    @skin.image.src = url
    return

draw = ->
  requestAnimationFrame draw
  renderer.render scene, camera

getJSON = (url, func) ->
  xhr = new XMLHttpRequest
  xhr.onreadystatechange = ->
    if xhr.readyState is xhr.DONE and 200 <= xhr.status <= 299
      func JSON.parse xhr.responseText
  xhr.open 'GET', url
  xhr.send null
  xhr

document.addEventListener "DOMContentLoaded", ((event) ->
  getJSON 'data/steve.json', (json) ->
    steve.model.add buildModel json
    steve.attachUI?()
  
  getJSON 'skins/skins.json', (skins) ->
    return unless skins.length > 0
    group = document.createElement 'optgroup'
    group.label = 'Preloaded Skins'
    for {name, url} in skins
      opt = document.createElement 'option'
      opt.value = url
      opt.textContent = name
      group.appendChild opt
    document.getElementById('avatar_skin').appendChild group
  
  document.body.appendChild renderer.domElement
  requestAnimationFrame draw
), false
