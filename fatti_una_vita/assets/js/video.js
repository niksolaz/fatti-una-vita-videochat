let Video = {}

async function waitForLiveViewReady(maxRetries = 10, interval = 5000) {
  return new Promise(resolve => {
    let tries = 0
    const check = () => {
      console.log("🧐 Checking liveSocket", window.liveSocket?.isConnected())
      if (window.liveSocket?.isConnected()) return resolve(true)
      if (++tries >= maxRetries) return resolve(false)
      setTimeout(check, interval)
    }
    check()
  })
}

Video.VideoChat = {
  mounted() {
    console.log("📹 VideoChat hook mounted")

    this.peer = new RTCPeerConnection({
      iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
    })
    console.log("🧱 PeerConnection creata", this.peer)
    window.myPeer = this.peer

    // Set up remote stream container
    this.remoteStream = new MediaStream()

    const remoteVideo = document.getElementById("remote-video")
    if (remoteVideo) {
      remoteVideo.srcObject = this.remoteStream
    }

    this.peer.addEventListener("track", (event) => {
      console.log("🔥 ontrack received", event.track.kind)
      this.remoteStream.addTrack(event.track)
      if (remoteVideo) {
        remoteVideo.play().then(() => {
          console.log("▶️ remoteVideo playing")
        }).catch(err => {
          console.warn("⚠️ remoteVideo play error:", err)
        })
      }
    })

    this.peer.addEventListener("iceconnectionstatechange", () => {
      console.log("🌍 ICE state:", this.peer.iceConnectionState)
    })

    // === Ottieni webcam ===
    navigator.mediaDevices.getUserMedia({ video: true, audio: true })
      .then(stream => {
        console.log("🎥 Webcam OK:", stream)
        this.localStream = stream

        const localVideo = document.getElementById("video-chat")
        if (localVideo) {
          localVideo.srcObject = stream
          localVideo.muted = true
          localVideo.autoplay = true
          localVideo.playsInline = true
        }

        stream.getTracks().forEach(track => {
          console.log("🔗 Aggiungo traccia:", track.kind)
          this.peer.addTrack(track, stream)
        })

        // SOLO main crea offerta
        if (window.location.href.includes("role=main")) {
          this.peer.onnegotiationneeded = async () => {
            console.log("⚙️ onnegotiationneeded, creo offer")
            await waitForLiveViewReady()
            if (!window.liveSocket?.isConnected()) return

            const offer = await this.peer.createOffer()
            await this.peer.setLocalDescription(offer)

            this.pushEvent("signal", {
              to: "all",
              data: {
                type: "offer",
                sdp: this.peer.localDescription
              }
            })
          }
        }
      })
      .catch(err => {
        console.error("❌ Errore webcam:", err)
      })

    // === ICE ===
    this.peer.onicecandidate = async (event) => {
      if (event.candidate) {
        await waitForLiveViewReady()
        this.pushEvent("signal", {
          to: "all",
          data: {
            type: "candidate",
            candidate: event.candidate
          }
        })
      }
    }

    // === Segnali ===
    this.handleEvent("signal", async ({ from, data }) => {
      console.log("📨 Ricevuto:", data.type)

      if (data.type === "offer") {
        await this.peer.setRemoteDescription(new RTCSessionDescription(data.sdp))

        if (this.pendingCandidates?.length) {
          for (const c of this.pendingCandidates) {
            await this.peer.addIceCandidate(new RTCIceCandidate(c))
          }
          this.pendingCandidates = []
        }

        const answer = await this.peer.createAnswer()
        await this.peer.setLocalDescription(answer)

        this.pushEvent("signal", {
          to: from,
          data: {
            type: "answer",
            sdp: this.peer.localDescription
          }
        })
      }

      if (data.type === "answer") {
        await this.peer.setRemoteDescription(new RTCSessionDescription(data.sdp))
      }

      if (data.type === "candidate") {
        try {
          const candidate = new RTCIceCandidate(data.candidate)
          if (this.peer.remoteDescription) {
            await this.peer.addIceCandidate(candidate)
          } else {
            this.pendingCandidates = this.pendingCandidates || []
            this.pendingCandidates.push(data.candidate)
          }
        } catch (err) {
          console.error("⚠️ ICE error:", err)
        }
      }
    })
  }
}

Video.CopyInvite = {
  mounted() {
    const button = this.el
    const input = document.getElementById("invite-url")

    button.addEventListener("click", () => {
      if (!input) return
      input.select()
      input.setSelectionRange(0, 99999)

      try {
        document.execCommand("copy")
        console.log("📋 URL copiato:", input.value)
        button.textContent = "✅ Copiato!"
        setTimeout(() => {
          button.textContent = "📋 Copia"
        }, 2000)
      } catch (err) {
        console.error("😩 Errore copia:", err)
      }
    })
  }
}

export default Video
