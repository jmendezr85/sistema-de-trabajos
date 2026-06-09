/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // add field
  collection.fields.addAt(20, new Field({
    "hidden": false,
    "id": "select4107906364",
    "maxSelect": 1,
    "name": "estado_diseno",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Asignado",
      "En Proceso",
      "Completado"
    ]
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // remove field
  collection.fields.removeById("select4107906364")

  return app.save(collection)
})
