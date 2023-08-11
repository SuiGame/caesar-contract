module suiGameNFT::suiGameStake {
    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};
    use suiGameNFT::SuiGameNFT;

    struct sNftPropertys has key, store{
        value: u64,
        owner: address,
    }
    struct sOwnNftIDs has key, store{
        NftIDs: vector<UID>
    }

    struct StakePool<T> has key, store {
        id: UID,
        name: string::String,
        description: string::String,
        rewardsToken: Coin<T>,
        periodFinish: u64,
        rewardRate: u64,
        rewardsDuration: u64,
        lastUpdateTime: u64,
        rewardPerTokenStored: u64,
        totalReward: u64,
        totalStakeTokens: u64,

        userRewardPerTokenPaid: Table<address, u64>,
        rewards: Table<address, u64>,
        _totalSupply: u64,
        _balances: Table<address, u64>,
        totalRewardAlready: u64,

        _stakingPoolNFTs: Table<ID, SuiGameNFT>,
        _stakingNFTs: Table<ID, sNftPropertys>,
        _OwnerNFTs: Table<address, sOwnNftIDs>,
        basicDailyReward: u64;
    }
    struct SuiGameManager has key, store {
        id: UID,
        name: string::String,
    }

    fun init(ctx: &mut TxContext) {
        let pool = StakePool {
            id: object::new(ctx),
            name:  string::utf8(b"SuiGameStake"),
            description: string::utf8(b"SuiGameStake"),
            periodFinish:0,
            rewardRate: 0,
            rewardsDuration: 6*30*24*3600*1000,
            lastUpdateTime: 0,
            rewardPerTokenStored:0,
            totalReward: 0,
            totalStakeTokens: 0,
            _totalSupply: 0,
            totalRewardAlready: 0,
            userRewardPerTokenPaid:table::new<address, u64>(ctx),
            rewards:table::new<address, u64>(ctx),

            _balances:table::new<address, u64>(ctx),
            _stakingNFTs:table::new<UID, sNftPropertys>(ctx),
            _OwnerNFTs:table::new<address, sOwnNftIDs>(ctx),
            basicDailyReward: 100000
        };
        transfer::share_object(pool);

        let manager = SuiGameManager {
            id: object::new(ctx),
            name:  string::utf8(b"SuiGameManager"),
        };
        transfer::public_transfer(manager, sender);

    }
    public entry fun  lastTimeRewardApplicable(pool: &mut StakePool,clock: &Clock): u64 {
        let timestamp = clock::timestamp_ms(clock);
        if(timestamp<pool.periodFinish) return timestamp;
        return pool.periodFinish;
    }
    public entry fun  rewardPerToken(pool: &mut StakePool,clock: &Clock): u64{
        if (pool._totalSupply == 0){
            return pool.rewardPerTokenStored;
        }
        let rewardPerToken0 =  rewardPerTokenStored+(
          (lastTimeRewardApplicable(pool,clock)-lastUpdateTime)*(rewardRate)*(1e18)/(_totalSupply)
          );
        return rewardPerToken0;
    }   
    fun earned_Stake(pool: &mut StakePool,clock: &Clock,address account): u64{
        return pool._balances[account]*(
          rewardPerToken(pool,clock)-(pool.userRewardPerTokenPaid[account])
        )/(1e18)+(pool.rewards[account]);
    }
    entry fun updateReward(pool: &mut StakePool,account:address){
        pool.rewardPerTokenStored = rewardPerToken(pool,clock);
        pool.lastUpdateTime = lastTimeRewardApplicable(pool,clock);
        if (account != address(0)){
           pool.rewards[account] = earned_Stake(pool,clock,account);
           pool.userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }
    public entry fun  notifyRewardAmount(_: &SuiGameManager,pool: &mut StakePool,reward:u64,clock: &Clock){
        updateReward(pool,clock,address(0));
        u64 timestamp = clock::timestamp_ms(clock);

        if (timestamp >= pool.periodFinish){
            pool.rewardRate = reward/pool.rewardsDuration;
        }
        else{
            u64 remaining = pool.periodFinish - timestamp;
            u64 leftover = remaining*rewardRate;
            pool.rewardRate = (reward+leftover)/pool.rewardsDuration;
        }
        pool.totalReward = totalReward+reward;
        assert!(coin::value(&pool.rewardsToken) >= amount, EInsufficientFunds);
        assert!(rewardRate <= balance/pool.rewardsDuration, 0);

        pool.lastUpdateTime = timestamp;
        pool.periodFinish = timestamp+pool.rewardsDuration;
    }
    public entry fun  setBasicDailyReward (_: &SuiGameManager,pool: &mut StakePool,newBasicDailyReward:u64 ) {
        pool.basicDailyReward = newBasicDailyReward ;
    }
    fun _msgSender(ctx: & TxContext):address{
        return tx_context::sender(ctx);
    }
    public entry fun  stakes(pool: &mut StakePool,clock: &Clock,nfts:vector<SuiGameNFT>) {
        updateReward(pool,clock,address(0));

        assert!(tokenIds.length<=100, 0);
        assert!(tokenIds.length>0, 1);
        for(u64 i=0; i<tokenIds.length; ++i) {
            _stake(pool.clock,tokenIds[i]);
        }
    }
    public entry fun  stake(pool: &mut StakePool,clock: &Clock,nft: SuiGameNFT){
        updateReward(pool,clock,address(0));
        _stake(pool,clock,tokenId);
    }
    fun getHashrateByTokenId(tokenId:UID):u64{
        SuiGameNFT nft(tokenId);
        return nft.hashrate;
    }
}
