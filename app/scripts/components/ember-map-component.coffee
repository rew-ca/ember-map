DreamcodeComponents.EmberMapComponent = Ember.Component.extend
  classNames: ["ember-map"]
  attributeBindings: [
    "lat", "lng", "zoom", "currentLocation",
    "swlat", "swlng", "nelat", "nelng"
  ]

  didInsertElement: -> @attachCanvas()
  willDestroyElement: -> @detachCanvas()

  attachCanvas: ->
    @buildMap()

    @addEventListeners()
    @centerMap()
    @updateZoom()

    if @map.getBounds()
      @updateBounds()
    else
      google.maps.event.addListenerOnce @map, "bounds_changed", =>
        Ember.run => @updateBounds()

  detachCanvas: ->
    @clearEventListeners()

  buildMap: ->
    # build and init
    @$().css(position: 'absolute', width: '100%', height: '100%')

    mapOptions =
      zoom: @get("zoom")
      center: new google.maps.LatLng(@get("lat"), @get("lng"))
      mapTypeId: google.maps.MapTypeId.ROADMAP
      disableDefaultUI: true
      zoomControl: true
      zoomControlOptions:
        style: google.maps.ZoomControlStyle.SMALL
        position: google.maps.ControlPosition.RIGHT_TOP

    @map = new google.maps.Map(@$()[0], mapOptions)
    @currentLocationMarker = @buildCurrentLocationMarker()

  buildCurrentLocationMarker: ->
    image =
      url: @currentLocationMarkerImageUrl
      size: null
      origin: null
      anchor: new google.maps.Point(32, 32)
      scaledSize: new google.maps.Size(64, 64)

    return new google.maps.Marker
      map: @map
      icon: image

  updateCurrentLocationMarker: (->
    location = @get("currentLocation")
    latlng = new google.maps.LatLng(location[0], location[1])
    @currentLocationMarker.setPosition(latlng)
  ).observes('currentLocation')

  centerMap: (->
    @map.setCenter new google.maps.LatLng(@get('lat'), @get('lng'))
  ).observes('lat', 'lng')

  updateBounds: (->
    sw = @map.getBounds().getSouthWest()
    ne = @map.getBounds().getNorthEast()

    @set "swlat", sw.lat()
    @set "swlng", sw.lng()
    @set "nelat", ne.lat()
    @set "nelng", ne.lng()
  ).observes("lat", "lng", "zoom")

  updateZoom: (->
    @map.setZoom @get("zoom")
  ).observes("zoom")

  addEventListeners: ->
    @customListeners = []

    dragendListener = google.maps.event.addListener @map, "dragend", (event) =>
      Ember.run =>
        center = @map.getCenter()
        @set "lat", center.lat()
        @set "lng", center.lng()

    zoomChangedListener = google.maps.event.addListener @map, "zoom_changed", (event) =>
      Ember.run =>
        @set "zoom", @map.getZoom()

    @customListeners.push(dragendListener)
    @customListeners.push(zoomChangedListener)

  clearEventListeners: ->
    google.maps.event.removeListener(listener) for listener in @customListeners
    @customListeners = []
