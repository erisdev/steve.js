"use strict"

rad = (deg) -> deg / 180 * Math.PI
deg = (rad) -> rad * 180 / Math.PI

steve.attachUI = ->
  delete steve.attachUI
  
  updateUI = ->
    if part = parts[ui.joints.value]
      ui.x.value = deg part.rotation.x
      ui.y.value = deg part.rotation.y
      ui.z.value = deg part.rotation.z
      document.getElementById('pose_joint_controls').style.display = 'block'
    else
      ui.x.value = 0
      ui.y.value = 0
      ui.z.value = 0
      document.getElementById('pose_joint_controls').style.display = 'none'
  
  hook = (id, events = {}) ->
    element = document.getElementById id
    element["on#{event}"] = handler for event, handler of events
    element
  
  ui =
    skins: hook 'avatar_skin',
      change: ->
        steve.loadSkin ui.skins.value
    rotation: hook 'avatar_rotation',
      change: ->
        steve.model.rotation.y = rad ui.rotation.valueAsNumber
    joints: hook 'pose_joint', change:updateUI
    x: hook 'pose_joint_x',
      change: ->
        if part = parts[ui.joints.value]
          part.rotation.x = rad ui.x.valueAsNumber
    y: hook 'pose_joint_y',
      change: ->
        if part = parts[ui.joints.value]
          part.rotation.y = rad ui.y.valueAsNumber
    z: hook 'pose_joint_z',
      change: ->
        if part = parts[ui.joints.value]
          part.rotation.z = rad ui.z.valueAsNumber
  
  parts = {}
  
  steve.model.traverse (part) ->
    if name = part.name
      parts[name] = part
      opt = document.createElement 'option'
      opt.value = name
      opt.textContent = name
      ui.joints.appendChild opt
  
  hook 'pose_joint_reset',
    click: ->
      if part = parts[ui.joints.value]
        part.rotation.set 0, 0, 0
      updateUI()
  
  hook 'pose_reset',
    click: ->
      for name, part of parts
        part.rotation.set 0, 0, 0
      updateUI()
  
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
      {skins} = ui
      
      unless draggedImageItem
        draggedImageItem = document.createElement 'option'
        if skins.childElementCount < 2
          skins.appendChild draggedImageItem
        else
          skins.insertBefore draggedImageItem, skins.children[1]
      
      draggedImageItem.value = url
      draggedImageItem.textContent = "(dragged image: #{file.name})"
      
      skins.value = url
      steve.loadSkin url
    
    reader.readAsDataURL file
  
  ui.joints.value = ''
  updateUI()