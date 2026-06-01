/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update field
  collection.fields.addAt(13, new Field({
    "hidden": false,
    "id": "select1052283506",
    "maxSelect": 1,
    "name": "ploteo_tipo",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Interior"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update field
  collection.fields.addAt(13, new Field({
    "hidden": false,
    "id": "select1052283506",
    "maxSelect": 1,
    "name": "ploteo_tipo",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Interior",
      "Exterior"
    ]
  }))

  return app.save(collection)
})
