// using from https://github.com/dappuniversity/dbank/tree/starter_kit
export const ETHER_ADDRESS = '0x0000000000000000000000000000000000000000'
export const EVM_REVERT = 'VM Exception while processing transaction: revert'
export const EVM_SENDER_ERR = 'Returned error: sender account not recognized'

export const ether = n => {
  return new web3.utils.BN(
    web3.utils.toWei(n.toString(), 'ether')
  )
}

// Same as ether
export const tokens = n => ether(n)

export const wait = s => {
  const milliseconds = s * 1000
  return new Promise(resolve => setTimeout(resolve, milliseconds))
}

// export const toBN = web3.utils.toBN;