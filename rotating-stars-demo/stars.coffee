# config
wrapper_id = 'wrapper'
width = 800
height = 400
star_number = 800
fps = 30

class Sky
    constructor: (@w, @h, @x, @y) ->

    # check if a point is in the visible region
    visible: (x, y) ->
        return x > 0 and y > 0 and x <= @w and y <= @h

class Star
    # initial position, rotating speed
    constructor: (@init_angle, @radius, @size, @speed) ->

    draw: (ctx, sky, time_elapsed) ->
        angle = @init_angle + (time_elapsed*@speed) % (2*Math.PI)
        x = - @radius * Math.cos angle
        y = @radius * Math.sin angle

        if not sky.visible(x, y)
            return

        ctx.beginPath()
        ctx.arc -x, -y, @size, 0, 2*Math.PI, true
        ctx.fill()


retinafy = (canvas) ->
    # technique from:
    # http://joubert.posterous.com/crisp-html-5-canvas-text-on-mobile-phones-and
    DPR = window.devicePixelRatio
    width = +canvas.getAttribute 'width'
    height = +canvas.getAttribute 'height'
    canvas.style.width = width + 'px'
    canvas.style.height = height + 'px'
    canvas.width = width * DPR
    canvas.height = height * DPR
    canvas.getContext('2d').scale(DPR, DPR)

requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame

div = document.getElementById wrapper_id
console.log div
canvas = document.createElement 'canvas'
canvas.width = width
canvas.height = height
div.appendChild canvas
console.log canvas

retinafy canvas

ctx = canvas.getContext '2d'
# set origin to bottom right corner
ctx.translate width, height
max_radius = Math.sqrt width*width + height*height
max_size = 2
speed = Math.PI / 60000

sky = new Sky width, height, 0, 0
stars = (new Star(Math.random() * 2 * Math.PI, Math.random() * max_radius, Math.random() * max_size, speed) for i in [1..star_number])

ms_per_frame = 1000 / fps
last_frame = 0

draw_sky = (time_stamp) ->
    if time_stamp - last_frame < ms_per_frame
        requestAnimationFrame(draw_sky)
        return

    last_frame = time_stamp

    ctx.fillStyle = 'black'
    ctx.fillRect 0, 0, -width, -height
    ctx.fillStyle = ctx.strokeStyle = 'white'
    star.draw ctx, sky, time_stamp for star in stars

    requestAnimationFrame(draw_sky)

requestAnimationFrame(draw_sky)
