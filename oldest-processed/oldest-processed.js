const fetchUrl = async (url, method, payload = {}, extraHeaders, shouldReturn = true) => {
  const res = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
      ...extraHeaders
    },
    body: JSON.stringify({
      CongregationId: 13596,
      ...payload
    })
  })
  if (shouldReturn) {
    const data = await res.json()
    return data
  }
}

const getTerritories = async () => {
  const territories = await fetchUrl(
    `${window.location.origin}/sv/Territory/GetTerritories/`,
    'POST'
  )
  return territories
}

const oldestReturned = (territories) => territories.map(val => {
  const regExParentheses = /\(([^)]+)\)/;
  if (val.TerritoryAssignments && val.TerritoryAssignments[0] && val.TerritoryAssignments[0].DateReturned) {
    const returnDate = regExParentheses.exec(val.TerritoryAssignments && val.TerritoryAssignments[0] && val.TerritoryAssignments[0].DateReturned)[1]
    const dateFixed = new Date(Number(returnDate)).toUTCString()
    return {
      id: val.Id,
      address: val.Address,
      returnDate,
      terId: `${val.TerritoryType.Name}, ${val.TerritoryType.Code}-${val.Number}`,
      dateFixed,
      notes: val.Notes,
    }
    return null
  }
})
  .filter(val => val)
  .sort((a, b) => a.returnDate - b.returnDate)
  .filter(val => !val.terId.includes('Landet') && !val.terId.includes('Snättringe'))

const loadingUi = (remove = false) => {
  console.log('loadingUi triggered')
  const id = 'loading-ui-continer'
  if (remove) {
    document.querySelector(`#${id}`) && document.querySelector(`#${id}`).remove()
  } else {
    loadingUi('remove')
    const div = document.createElement('div')
    div.id = id
    div.innerHTML = 'Hämtar data ...'
    div.style.padding = '20px'
    div.style.position = 'absolute'
    div.style.top = '20%'
    div.style.left = '5px'
    div.style.width = '100vw'
    div.style.zIndex = '1000'
    div.style.fontWeight = 'bold'
    div.style.textAlign = 'center'
    div.style.background = '#48535f'
    div.style.color = '#ffffff'
    document.body.appendChild(div)
  }
}

const showData = (data, type = 'Sist bearbetade') => {
  const containerId = 'sist-bearbetade'
  const newDiv = () => document.createElement('div')
  const container = newDiv()
  container.id = containerId
  container.style.height = '100vh'
  container.style.width = '100vw'
  container.style.background = '#3b414994'
  container.style.position = 'absolute'
  container.style.top = '0'
  const innerContainer = newDiv()
  innerContainer.style.height = '600px'
  innerContainer.style.width = '700px'
  innerContainer.style.position = 'absolute'
  innerContainer.style.top = '10%'
  innerContainer.style.left = '20%'
  innerContainer.style.background = '#cccccc'
  innerContainer.style.borderRadius = '10px'
  innerContainer.style.boxShadow = '0px 1px 10px #ddd'
  innerContainer.style.padding = '15px'
  innerContainer.style.overflow = 'scroll'
  innerContainer.innerHTML = `<h2>${type} - (${data.length} st.)</h2>`
  console.log(`${type} raw data:`)
  console.log(data)
  const insertData = (data) => {
    innerContainer.innerHTML = innerContainer.innerHTML + `
<div style="padding:15px">
  <p>Adress: ${data.address}</p>
  <p>Senast inlämnat datum: ${data.dateFixed.substring(0, 16)}</p>
  <p>Anteckningar: ${data.notes}</p>
  <p>Namn: ${data.terId}</p>
  <a target="_blank" href="${`${window.location.origin}/sv/View/Territory/${data.id}`}">Öppna distrikt</a>
</div>
<hr />
`
  }
  data.forEach(val => insertData(val))

  container.appendChild(innerContainer)
  document.body.appendChild(container)
  loadingUi('remove')
  console.log('done')
}

const showDataMiddleware = (data, label) => {
  loadingUi()
  setTimeout(() => {
    showData(data, label)
  }, 500)
}

const addButtons = () => {
  const createBtn = () => {
    const btn = document.createElement('button')
    btn.style.margin = '5px'
    return btn
  }
  const container = document.createElement('div')
  container.style.position = 'absolute'
  container.style.top = '4px'
  container.style.right = '4px'
  container.style.zIndex = '1000'
  const latest = createBtn()
  const latestVillor = createBtn()
  const latestRadhus = createBtn()
  const register = createBtn()
  register.innerHTML = 'Öppna register'
  latest.innerHTML = 'Sist (alla)'
  latestVillor.innerHTML = 'Sist villor'
  latestRadhus.innerHTML = 'Sist radhus'
  register.onclick = () => window.open('https://territoryhelper.com/sv/Assignments')
  latest.onclick = () => showDataMiddleware(window._oldest_returned_, 'Sist bearbetade')
  latestVillor.onclick = () => showDataMiddleware(window.oldest_villor, 'Sist bearbetade villor')
  latestRadhus.onclick = () => showDataMiddleware(window.oldest_radhus, 'Sist bearbetade radhus/villor')
  container.appendChild(register)
  container.appendChild(latest)
  container.appendChild(latestVillor)
  container.appendChild(latestRadhus)
  document.body.insertBefore(container, null)
  console.log('addButtons done')
  loadingUi('remove')
}

const start = async () => {
  loadingUi()
  const territories = await getTerritories()
  const ter = oldestReturned(territories)
  window._oldest_returned_ = ter
  window.oldest_villor = window._oldest_returned_.filter(val =>
    val.notes.includes('Villor') || val.notes.includes('villor'))
  window.oldest_radhus = window._oldest_returned_.filter(val =>
    val.notes.includes('Radhus') || val.notes.includes('radhus'))
  console.log(ter[0])
  addButtons()
}

start()
