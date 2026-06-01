/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select3633164863",
    "maxSelect": 1,
    "name": "Tipo_de_trabajo",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Diseño/Corte",
      "Impresión Laser",
      "Ploteo Interior",
      "Ploteo Exterior"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select3633164863",
    "maxSelect": 1,
    "name": "Tipo_de_trabajo",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Diseño/Corte",
      "Laser",
      "Ploteo Interior",
      "Ploteo Exterior"
    ]
  }))

  return app.save(collection)
})
