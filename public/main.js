// hook tailwind and show the stats
const canvas = document.querySelector('canvas')
const ctx = canvas.getContext('2d')

const width = canvas.width
const height = canvas.height

const imageData = ctx.createImageData(width, height)
const data = imageData.data

function assert(condition, message) {
    if (condition) return
    throw new Error(message || "assertion failed")
}

let wasm_mod = null
async function load_wasm() {
  if (!wasm_mod) {
    const response = await fetch('ai.wasm')
    const bytes = await response.arrayBuffer()
    const { instance } = await WebAssembly.instantiate(bytes)

    wasm_mod = instance.exports
    wasm_mod.initbetween()
  }

  return wasm_mod
}

async function guess() {
  assert(data.length == 28 * 28 * 4)

  const input = new Float32Array(28 * 28)
  const output = new Float32Array(10)

  for (let i = 0; i < input.length; i++) {
    input[i] = data[i * 4] / 255.0
  }

  const wasm = await load_wasm()
  const mem = new Float32Array(wasm.memory.buffer)

  mem.set(input, 0)
  wasm.guess(0, input.length, 28 * 28 * 4, output.length)

  console.log(mem.subarray(28 * 28, 28 * 28 + 10))
}

for (let i = 0; i < data.length; i += 4) {
  data[i + 0] = 0
  data[i + 1] = 0
  data[i + 2] = 0
  data[i + 3] = 255
}

ctx.putImageData(imageData, 0, 0)

const brushRadius = 2
let isDrawing = false
let lastPos = null

function drawAtPixel(cx, cy) {
  for (let dy = -brushRadius; dy <= brushRadius; dy++) {
    for (let dx = -brushRadius; dx <= brushRadius; dx++) {
      const x = cx + dx
      const y = cy + dy

      if (x >= 0 && x < width && y >= 0 && y < height) {
        const dist = Math.sqrt(dx * dx + dy * dy)
        if (dist <= brushRadius) {
          const alphaFactor = 1 - dist / brushRadius
          const index = (y * width + x) * 4

          const existing = data[index + 0]
          const added = Math.floor(255 * alphaFactor)
          data[index + 0] = Math.min(existing + added, 255)
          data[index + 1] = Math.min(existing + added, 255)
          data[index + 2] = Math.min(existing + added, 255)
          data[index + 3] = 255
        }
      }
    }
  }
}

function getCanvasCoords(e) {
  const rect = canvas.getBoundingClientRect()
  const scaleX = canvas.width / rect.width
  const scaleY = canvas.height / rect.height
  const x = Math.floor((e.clientX - rect.left) * scaleX)
  const y = Math.floor((e.clientY - rect.top) * scaleY)
  return { x, y }
}

function drawLine(from, to) {
  const dx = to.x - from.x
  const dy = to.y - from.y
  const steps = Math.max(Math.abs(dx), Math.abs(dy))
  for (let i = 0; i <= steps; i++) {
    const x = Math.round(from.x + (dx * i) / steps)
    const y = Math.round(from.y + (dy * i) / steps)
    drawAtPixel(x, y)
  }
  ctx.putImageData(imageData, 0, 0)
}

canvas.addEventListener('mousedown', e => {
  isDrawing = true
  lastPos = getCanvasCoords(e)
  drawAtPixel(lastPos.x, lastPos.y)
  ctx.putImageData(imageData, 0, 0)
})

canvas.addEventListener('mousemove', e => {
  if (!isDrawing) return
  const newPos = getCanvasCoords(e)
  drawLine(lastPos, newPos)
  lastPos = newPos
})

canvas.addEventListener('mouseup', () => {
  isDrawing && guess()
  isDrawing = false
  lastPos = null
})

canvas.addEventListener('mouseleave', () => {
  isDrawing && guess()
  isDrawing = false
  lastPos = null
})
