# config
wrapper_id = 'wrapper'
width = document.documentElement.clientWidth
height = document.documentElement.clientHeight
star_number = Math.floor 0.001 * width * height
fps = 30

class Sky
    constructor: (@w, @h, @x, @y) ->
        @x_upper = @w - @x
        @x_lower = - @x
        @y_upper = @h - @y
        @y_lower = - @y

    # check if a point is in the visible region
    visible: (x, y) ->
        return x >= @x_lower and x <= @x_upper and y >= @y_lower and y <= @y_upper

class Star
    # initial position, rotating speed, brightness (0-1)
    constructor: (@init_angle, @radius, @size, @speed, @max_brightness) ->
        @bright_offset = Math.random() * 2 * Math.PI

    draw: (ctx, sky, time_elapsed) ->
        angle = @init_angle + (time_elapsed*@speed) % (2*Math.PI)
        x = @radius * Math.cos angle
        y = - @radius * Math.sin angle

        if not sky.visible x, y
            return

        brightness = ((1+Math.sin(0.001*time_elapsed+@bright_offset)) / 2 + 0.05) * @max_brightness
        ctx.fillStyle = ctx.strokeStyle = "rgba(255, 255, 255, #{brightness}"
        # draw star
        # since we gonna change origin and rotate, save context state first
        ctx.save()
        ctx.translate x, y
        ctx.rotate angle
        @drawCross(@size)
        brightness = brightness * 0.75
        ctx.fillStyle = ctx.strokeStyle = "rgba(255, 255, 255, #{brightness}"
        ctx.rotate 0.25*Math.PI
        @drawCross(@size*4/5)
        ctx.restore()

    drawCross: (size) ->
        ctx.beginPath()
        inner_side = size
        outer_side = 2.5 * inner_side
        ctx.moveTo inner_side, 0
        ctx.lineTo outer_side, -outer_side
        ctx.lineTo 0, -inner_side
        ctx.lineTo -outer_side, -outer_side
        ctx.lineTo -inner_side, 0
        ctx.lineTo -outer_side, outer_side
        ctx.lineTo 0, inner_side
        ctx.lineTo outer_side, outer_side
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
canvas.width = document.documentElement.clientWidth
canvas.height = document.documentElement.clientHeight
div.appendChild canvas
console.log canvas

retinafy canvas

max_radius = Math.sqrt width*width + height*height
max_size = 2
speed = Math.PI / 100000

random_star = (speed, max_radius, max_size) ->
    init_angle = Math.random() * 2 * Math.PI
    radius = Math.random() * max_radius
    size = Math.random() * max_size
    max_brightness = (Math.random()+0.5)/1.5
    return new Star(init_angle, radius, size, speed, max_brightness)

center_x = width
center_y = height
sky = new Sky width, height, center_x, center_y
stars = (random_star(speed, max_radius, max_size) for i in [1..star_number])

ctx = canvas.getContext '2d'
# set origin to bottom right corner
ctx.translate center_x, center_y

ms_per_frame = 1000 / fps
last_frame = 0

draw_sky = (time_stamp) ->
    if time_stamp - last_frame < ms_per_frame
        requestAnimationFrame draw_sky
        return

    last_frame = time_stamp

    ctx.fillStyle = 'black'
    ctx.fillRect 0, 0, -width, -height
    star.draw ctx, sky, time_stamp for star in stars

    requestAnimationFrame draw_sky

requestAnimationFrame draw_sky
