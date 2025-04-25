defmodule FattiUnaVitaWeb.RoomLive do
  use FattiUnaVitaWeb, :live_view

  @default_list_of_messages [
    "almeno una passeggiata.",
    "almeno provaci!",
    "almeno parla con un amico dal vivo.",
    "almeno vai a farti uno spritz.",
    "almeno goditi la natura.",
    "almeno prenditi un caffè o the.",
    "almeno gioca con i tuoi figli, se ne hai.",
    "almeno gioca con il tuo animale, se ne hai.",
    "almeno trovati un compagno/a per una passeggiata."
  ]

  @default_list_emoji [
    128540, 128541, 128542, 128543, 128544,
    128556, 129312, 128529, 128523, 128521, 128516
  ]

  def mount(%{"id" => room_id, "role" => role, "duration" => duration}, _session, socket) do
    minutes = String.to_integer(duration || "10")

    if connected?(socket) do
      Process.send_after(self(), :end_call, minutes * 60 * 1000)
    end

    invite_url =
      if role == "main" do
        url(~p"/room/#{room_id}?role=invited&duration=#{minutes}")
      else
        nil
      end

    {:ok,
     assign(socket,
       room_id: room_id,
       role: role,
       ended?: false,
       duration_minutes: minutes,
       invite_url: invite_url
     )}
  end

  def handle_info({:signal, from, _to, data}, socket) do
    push_event(socket, "signal", %{from: from, data: data})
    {:noreply, socket}
  end

  def handle_info(:end_call, socket) do
    {:noreply, assign(socket, ended?: true)}
  end

  def handle_event("signal", %{"to" => to, "data" => data}, socket) do
    IO.inspect({:received_signal, to, data})

    Phoenix.PubSub.broadcast(
      FattiUnaVita.PubSub,
      "room:#{socket.assigns.room_id}",
      {:signal, socket.id, to, data}
    )

    {:noreply, socket}
  end

  def handle_event("leave", _params, socket) do
    push_event(socket, "cleanup", %{})
    {:noreply, assign(socket, ended?: true)}
  end

  def message_for_end_of_call do
    Enum.random(@default_list_of_messages)
  end

  def message_for_end_of_call_emoji do
    Enum.random(@default_list_emoji)
  end

  def message_for_end_of_call_emoji_for_btn do
    Enum.random(@default_list_emoji)
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-screen bg-stone-100 text-center p-8">
      <%= if @ended? do %>
        <h1 class="text-3xl font-bold text-red-700">Fine della riunione.</h1>
        <p class="mt-4 text-2xl text-stone-700 font-semibold">Fatti una vita.</p>
        <p class="mt-4 text-1xl text-stone-700 font-semibold">oppure</p>
        <p class="mt-4 text-2xl text-stone-700 font-semibold"><%= message_for_end_of_call() %></p>
        <p class="text-9xl py-5">&#<%= message_for_end_of_call_emoji() %>;</p>
      <% else %>
        <h1 class="text-2xl font-semibold text-stone-800">Stanza ID: <%= @room_id %> (<%= @role %>)</h1>
        <p class="text-md text-stone-600">Durata: <%= @duration_minutes %> minuti</p>

        <%= if @role == "main" do %>
          <div class="mt-4">
            <label class="block text-sm text-gray-500">Link per invitare qualcuno:</label>
            <div class="flex items-center gap-2 mt-2">
              <input id="invite-url" readonly class="w-full text-sm px-3 py-1 border rounded text-gray-700" value={@invite_url} />
              <button phx-hook="CopyInvite" id="copy-btn" class="bg-blue-500 text-white px-2 py-1 rounded hover:bg-blue-600 transition duration-150">📋 Copia</button>
            </div>
          </div>
        <% end %>

        <video id="video-chat" phx-hook="VideoChat" class="w-full max-w-2xl h-96 bg-black mt-6 rounded shadow-inner" muted></video>
        <video id="remote-video" class="w-full max-w-2xl h-96 bg-black mt-4 rounded shadow-inner" autoplay playsinline></video>

        <p class="mt-4 text-1xl text-stone-700 font-semibold">Fatti una vita! Abbandona con dignità.</p>
        <button phx-click="leave" class="mt-8 bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-full shadow-lg transition duration-150">
          Me ne vado &#<%= message_for_end_of_call_emoji_for_btn() %>;
        </button>
      <% end %>
    </div>
    """
  end
end
