import { assert, expect } from 'chai'
import { tokens, ether, wait, toBN, ETHER_ADDRESS, EVM_REVERT, EVM_SENDER_ERR } from '../helpers/helpers.js'

const Staking = artifacts.require("Staking");
const StakingPool = artifacts.require("StakingPool");
const LendingPool = artifacts.require("LendingPool");
const Token = artifacts.require("Token");

require('chai').use(require('chai-as-promised')).should();

contract('StakingPool', accounts => {
    let stakingPool;
    let lendingPool;
    let token;

    beforeEach(async() => {
        stakingPool = await StakingPool.new();
        lendingPool = await LendingPool.new();
        token = await Token.new(accounts[8], accounts[9], await stakingPool.address);

        await stakingPool.initialize(
            token.address,
            lendingPool.address
        );
    })

    describe('Testing initializing function...', () => {
        it('should deny to initialize again', async() => {
            await stakingPool.initialize(
                token.address,
                lendingPool.address
            ).should.be.rejectedWith(EVM_REVERT);
        })
    })
    
    describe('Testing stake and unstake of users...', () => {
        it('should add stake to users staking pool balance', async() => {

            await stakingPool.stake(tokens(0.01).toString(), { from: accounts[1] });
            const res =  await stakingPool.users(accounts[1]);
            expect(res.total.toString()).to.be.eq(tokens(0.01).toString());
        })

        it('should unstake users balance from staking pool', async() => {
            await stakingPool.stake(tokens(0.01).toString(), { from: accounts[1] });
            await stakingPool.unstake(tokens(0.006).toString(), { from: accounts[1]});
            var res = await stakingPool.users(accounts[1]);
            expect(res.total.toString()).to.be.eq(tokens(0.004).toString());
            await stakingPool.unstake(tokens(0.004).toString(), { from: accounts[1]});
            res = await stakingPool.users(accounts[1]);
            expect(res.total.toString()).to.be.eq('0');
        })
        
        it('should stake and unstake users balances in the staking pool with multiple users interacting', async() => {
            await stakingPool.stake(tokens(1).toString(), { from: accounts[1]});
            var res = await stakingPool.users(accounts[1]);
            expect(res.total.toString()).to.be.eq(tokens(1).toString());

            await stakingPool.stake(tokens(0.5).toString(), { from: accounts[2]});
            res = await stakingPool.users(accounts[2]);
            expect(res.total.toString()).to.be.eq(tokens(0.5).toString());

            await stakingPool.unstake(tokens(0.25).toString(), { from: accounts[1]});
            res = await stakingPool.users(accounts[1]);
            expect(res.total.toString()).to.be.eq(tokens(0.75).toString());

            await stakingPool.stake(tokens(0.5).toString(), { from: accounts[3]});
            res = await stakingPool.users(accounts[3]);
            expect(res.total.toString()).to.be.eq(tokens(0.5).toString());

            await stakingPool.unstake(tokens(0.5).toString(), { from: accounts[2]});
            res = await stakingPool.users(accounts[2]);
            expect(res.total.toString()).to.be.eq('0');

            await stakingPool.unstake(tokens(0.5).toString(), { from: accounts[1]});
            res = await stakingPool.users(accounts[1]);
            expect(res.total.toString()).to.be.eq(tokens(0.25).toString());
        })

        it('should deny unstake from first-time user', async() => {
            await stakingPool.unstake(tokens(0.01).toString(), { from: accounts[1]}).should.be.rejectedWith(EVM_REVERT);
        })

        it('should deny unstaking higher amount than staked by the user', async() => {
            await stakingPool.stake(tokens(1).toString(), {from: accounts[1]});
            await stakingPool.unstake(tokens(1.01).toString(), { from: accounts[1]}).should.be.rejectedWith(EVM_REVERT);
        })

        it('should increase users reward', async() => {

            await stakingPool.stake(tokens(0.01).toString(), {from: accounts[1]} );
            
            // wait so it takes 2 sec on chain
            await wait(1.99);

            await stakingPool.stake(tokens(0.01).toString(), {from: accounts[1]} );

            // wait so it takes 2 sec on chain
            await wait(1.99);

            await stakingPool.stake(tokens(0.01).toString(), {from: accounts[1]} );
            const res = await stakingPool.users(accounts[1]);
            expect(Number(res.interest.toString())).to.be.eq(3329528158295281);
        })

        it('should increase users rewards', async() => {
            await stakingPool.stake(tokens(0.01).toString(), {from: accounts[1]} );
            
            // wait so it takes 2 sec on chain
            await wait(1.99);

            await stakingPool.stake(tokens(0.01).toString(), {from: accounts[2]} );

            // wait so it takes 2 sec on chain
            await wait(1.99);

            await stakingPool.stake(tokens(0.01).toString(), {from: accounts[1]} );
            const res = await stakingPool.users(accounts[1]);
            expect(Number(res.interest.toString())).to.be.eq(1664764079147640);

            // wait so it takes 2 sec on chain
            await wait(1.99);

            await stakingPool.unstake(tokens(0.01).toString(), {from: accounts[2]} );
            const res2 = await stakingPool.users(accounts[2]);
            expect(Number(res2.interest.toString())).to.be.eq(3329528158295281);
        })
    })

    describe('Testing stake and unstake of the reserve...', () => {
        it('should add stake to the staking pool reserve balance', async() => {

            await stakingPool.stake(tokens(0.01).toString(), { from: accounts[1] });
            const res =  await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(0.01).toString());
        })

        it('should unstake balance from the staking pool reserve with one user interacting', async() => {
            await stakingPool.stake(tokens(0.01).toString(), { from: accounts[1] });
            await stakingPool.unstake(tokens(0.006).toString(), { from: accounts[1]});
            var res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(0.004).toString());
            await stakingPool.unstake(tokens(0.004).toString(), { from: accounts[1]});
            res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(0).toString());
        })

        it('should stake and unstake balance in the staking pool reserve with multiple users interacting', async() => {
            await stakingPool.stake(tokens(1).toString(), { from: accounts[1]});
            var res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(1).toString());

            await stakingPool.stake(tokens(0.5).toString(), { from: accounts[2]});
            res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(1.5).toString());

            await stakingPool.unstake(tokens(0.25).toString(), { from: accounts[1]});
            res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(1.25).toString());

            await stakingPool.stake(tokens(0.5).toString(), { from: accounts[3]});
            res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(1.75).toString());

            await stakingPool.unstake(tokens(0.5).toString(), { from: accounts[2]});
            res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(1.25).toString());

            await stakingPool.unstake(tokens(0.5).toString(), { from: accounts[1]});
            res = await stakingPool.stakingReserve();
            expect(res.total.toString()).to.be.eq(tokens(0.75).toString());
        })
    })

    describe('Testing slashing by the lending pool', () => {
        it('should allow to slash by lending pool', async() => {
            var res = await stakingPool.slash.call('0', { from: lendingPool.address});
            expect(res).to.be.eq(true);
        })

        it('should deny to slash by another address other than lending pool', async() => {
            await stakingPool.slash(0, {from: stakingPool.address}).should.be.rejectedWith(EVM_SENDER_ERR);
        })

        it('should deny to slash by trying to slash from the empty reserve', async() => {
            var res = await stakingPool.slash.call('1', { from: lendingPool.address});
            expect(res).to.be.eq(true);
        })
    })
})