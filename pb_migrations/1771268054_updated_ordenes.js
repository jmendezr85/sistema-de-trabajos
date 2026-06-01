/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "select569500885",
    "maxSelect": 1,
    "name": "Estado",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Pendiente",
      "Pago"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "select569500885",
    "maxSelect": 1,
    "name": "Estado",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Pendiente"
    ]
  }))

  return app.save(collection)
})
