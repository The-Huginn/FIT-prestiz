import { expect } from 'chai'
import { tokens, ether, ETHER_ADDRESS, EVM_REVERT, wait } from '../helpers/helpers.js'

const Token = artifacts.require('./Token.sol')

require('chai')
    .use(require('chai-as-promised'))
        .should()

contract('Token', accounts => {
    let token

    beforeEach(async() => {
        token = await Token.new(accounts[0], accounts[1], accounts[2]);
    })

    describe('Testing token contract...', () => {
        let team = 45*10**5
        let ico = 45*10**5
        let protocol = 21*10**6

        it('checking token name', async() => {
            expect(await token.name()).to.be.eq('FIT coin')
        })

        it('checking token symbol', async() => {
            expect(await token.symbol()).to.be.eq('FITCOIN')
        })

        it('checking token initial total supply', async() => {
            expect((await token.totalSupply()).toString()).to.eq(web3.utils.toWei((team + ico + protocol).toString()))
        })

        it('checking initial team, ico and community account supply', async() => {
            expect((await token.balanceOf(accounts[0])).toString()).to.be.eq(web3.utils.toWei(team.toString()))
            expect((await token.balanceOf(accounts[1])).toString()).to.be.eq(web3.utils.toWei(ico.toString()))
            expect((await token.balanceOf(accounts[2])).toString()).to.be.eq(web3.utils.toWei(protocol.toString()))
        })
    })
})