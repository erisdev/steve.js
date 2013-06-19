"use strict"

THREE.ImageUtils.crossOrigin = ''

[width, height] = [600, 600]

scene = new THREE.Scene()
scene.add new THREE.AmbientLight(0xCCCCCC)

light = new THREE.PointLight(0xFFFFFF)
light.position.set 0, 3, 10
scene.add light

camera = new THREE.PerspectiveCamera(45, width / height, 1, 100)
camera.position.set 0, 3, 5
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
    
    if data.name?
      part.name = data.name
      avatar.parts[data.name] = part
    
    part.position.set data.offset... if data.offset?
    part

avatar =
  parts: {}
  skin: skin
  model: do ->
    model = new THREE.Object3D()
    model.scale.set 0.1, 0.1, 0.1
    scene.add model
    model
  
  loadSkin: (url) ->
    avatar.skin.image.src = url
    return

attachUI = (avatar) ->
  rad = (deg) -> deg / 180 * Math.PI
  
  resetUI = ->
    if part = avatar.parts[jointField.value]
      xField.value = part.rotation.x
      yField.value = part.rotation.y
      zField.value = part.rotation.z
    else
      xField.value = 0
      yField.value = 0
      zField.value = 0
  
  skinField = document.getElementById 'avatar_skin'
  skinField.onchange = -> avatar.loadSkin skinField.value
  
  rotationField = document.getElementById 'avatar_rotation'
  rotationField.onchange = ->
    avatar.model.rotation.y = rad rotationField.valueAsNumber
  
  xField = document.getElementById 'pose_joint_x'
  xField.onchange = ->
    if part = avatar.parts[jointField.value]
      part.rotation.x = rad xField.valueAsNumber
  
  yField = document.getElementById 'pose_joint_y'
  yField.onchange = ->
    if part = avatar.parts[jointField.value]
      part.rotation.y = rad yField.valueAsNumber
  
  zField = document.getElementById 'pose_joint_z'
  zField.onchange = ->
    if part = avatar.parts[jointField.value]
      part.rotation.z = rad zField.valueAsNumber
  
  jointField = document.getElementById 'pose_joint'
  jointField.onchange = -> resetUI()
  
  for name, part of avatar.parts
    opt = document.createElement 'option'
    opt.value = name
    opt.textContent = name
    jointField.appendChild opt
  
  document.getElementById('pose_joint_reset').onclick = ->
    if part = avatar.parts[jointField.value]
      part.rotation.set 0, 0, 0
    resetUI()
  
  document.getElementById('pose_reset').onclick = ->
    for name, part of avatar.parts
      part.rotation.set 0, 0, 0
    resetUI()
  
  draggedImageItem = null
  
  document.body.ondragover = (event) ->
    event.stopPropagation()
    event.preventDefault()
    event.dataTransfer.dropEffect = 'copy'
  
  document.body.ondrop = (event) ->
    event.stopPropagation()
    event.preventDefault()
    
    file = event.dataTransfer.files?[0]
    return unless file?.type is 'image/png'
    
    reader = new FileReader
    reader.onload = (event) ->
      url = event.target.result
      
      unless draggedImageItem
        draggedImageItem = document.createElement 'option'
        if skinField.childElementCount < 2
          skinField.appendChild draggedImageItem
        else
          skinField.insertBefore draggedImageItem, skinField.children[1]
      
      draggedImageItem.value = url
      draggedImageItem.textContent = "(dragged image: #{file.name})"
      
      skinField.value = url
      avatar.loadSkin url
    
    reader.readAsDataURL file

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
  getJSON 'data/steve.json', (steve) ->
    avatar.model.add buildModel steve
    attachUI avatar
  
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
