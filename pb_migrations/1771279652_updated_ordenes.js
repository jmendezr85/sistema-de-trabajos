/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // update collection data
  unmarshal({
    "indexes": [
      "CREATE UNIQUE INDEX `idx_OxBspekYZa` ON `ordenes` (`ticket_no`)"
    ]
  }, collection)

  // add field
  collection.fields.addAt(10, new Field({
    "hidden": false,
    "id": "number4240351957",
    "max": null,
    "min": null,
    "name": "ancho_cm",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(11, new Field({
    "hidden": false,
    "id": "number3133127256",
    "max": null,
    "min": null,
    "name": "alto_cm",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(12, new Field({
    "hidden": false,
    "id": "select2092856725",
    "maxSelect": 1,
    "name": "material",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "Vinilo",
      "Lona",
      "Fotográfico",
      "Propalcote",
      "Pergamino",
      "Lienzo"
    ]
  }))

  // add field
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

  // add field
  collection.fields.addAt(14, new Field({
    "hidden": false,
    "id": "number2030646939",
    "max": null,
    "min": null,
    "name": "valor_ploteo_manual",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(15, new Field({
    "hidden": false,
    "id": "number2167461261",
    "max": null,
    "min": null,
    "name": "costo_material",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(16, new Field({
    "hidden": false,
    "id": "number696831517",
    "max": null,
    "min": null,
    "name": "costo_ploteo",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(17, new Field({
    "hidden": false,
    "id": "number470505744",
    "max": null,
    "min": null,
    "name": "costo_extras",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(18, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text3731403945",
    "max": 0,
    "min": 0,
    "name": "extras_detalle",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // update field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select3633164863",
    "maxSelect": 4,
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

  // update collection data
  unmarshal({
    "indexes": []
  }, collection)

  // remove field
  collection.fields.removeById("number4240351957")

  // remove field
  collection.fields.removeById("number3133127256")

  // remove field
  collection.fields.removeById("select2092856725")

  // remove field
  collection.fields.removeById("select1052283506")

  // remove field
  collection.fields.removeById("number2030646939")

  // remove field
  collection.fields.removeById("number2167461261")

  // remove field
  collection.fields.removeById("number696831517")

  // remove field
  collection.fields.removeById("number470505744")

  // remove field
  collection.fields.removeById("text3731403945")

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
})
