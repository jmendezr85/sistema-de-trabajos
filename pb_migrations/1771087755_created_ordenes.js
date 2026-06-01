/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = new Collection({
    "createRule": null,
    "deleteRule": null,
    "fields": [
      {
        "autogeneratePattern": "[a-z0-9]{15}",
        "hidden": false,
        "id": "text3208210256",
        "max": 15,
        "min": 15,
        "name": "id",
        "pattern": "^[a-z0-9]+$",
        "presentable": false,
        "primaryKey": true,
        "required": true,
        "system": true,
        "type": "text"
      },
      {
        "autogeneratePattern": "",
        "hidden": false,
        "id": "text4095515429",
        "max": 0,
        "min": 0,
        "name": "cliente",
        "pattern": "",
        "presentable": false,
        "primaryKey": false,
        "required": false,
        "system": false,
        "type": "text"
      },
      {
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
      },
      {
        "hidden": false,
        "id": "number3507727009",
        "max": null,
        "min": null,
        "name": "Monto",
        "onlyInt": false,
        "presentable": false,
        "required": false,
        "system": false,
        "type": "number"
      },
      {
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
      }
    ],
    "id": "pbc_3299786656",
    "indexes": [],
    "listRule": null,
    "name": "ordenes",
    "system": false,
    "type": "base",
    "updateRule": null,
    "viewRule": null
  });

  return app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656");

  return app.delete(collection);
})
