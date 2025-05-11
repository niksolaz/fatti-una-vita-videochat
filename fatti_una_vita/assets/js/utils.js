let Utils = {}

Utils.RoomConfig = {
  mounted() {
    const select = document.getElementById("duration-select")
    const link = document.getElementById("create-room-link")
    const randomId = Math.random().toString(36).substring(2, 15)
    link.classList.toggle("pointer-events-none", select.value === "0")
    link.classList.toggle("opacity-50", select.value === "0")

    
    if (!select || !link) {
      console.warn("RoomConfig hook: elementi mancanti")
      return
    }

    select.addEventListener("change", () => {
      const minutes = select.value
      const newHref = select.value === "0" ? `#` : `/room/${randomId}?role=main&duration=${minutes}`
      link.setAttribute("href", newHref)
      link.classList.toggle("pointer-events-none", minutes === "0")
      link.classList.toggle("opacity-50", minutes === "0")
    })
  }
}

export default Utils
