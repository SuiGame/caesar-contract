module suiGameNFT::SuiGameNFT {
    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};

    struct SuiGameNFT has key, store {
        id: UID,
        name: string::String,
        description: string::String,
        url: Url,
        degree: u64,
        subDegree:  u64,
        feedTime: u64,
        hashrate: u64,
        hp: u64,
        str: u64,
        mag: u64,
        inT: u64,
        gold: u64,
        bMedalNFTs: vector<bool>
    }
    struct MedalNFT has key, store {
        id: UID,
        name: string::String,
        description: string::String,
        url: Url,
    }
    struct NFTPool has key, store {
        id: UID,
        addressMint: Table<address, u64>,
        addressVault: address,
        addressInvite: Table<address, address>,
    }

    const FeedDt: u64 = 10000;
    const MaxDegree: u64 = 12;
    const MaxMint: u64 = 20;
    const FeedAmount: u64 = 20_000_000_000;

    struct MintNFTEvent has copy, drop {
        object_id: ID,
        creator: address,
        name: string::String,
    }

    fun init(ctx: &mut TxContext) {
        let nftPool = NFTPool {
            id: object::new(ctx),
            addressMint:table::new<address, u64>(ctx),
            addressInvite:table::new<address, address>(ctx)
        };
        transfer::share_object(nftPool);
    }

    public entry fun mint( pool: &mut NFTPool, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        if (!table::contains(&pool.addressMint, sender)) {
            table::add(&mut pool.addressMint, sender,  0);
        }
        let item = table::borrow_mut(&pool.addressMint, sender);
        assert!(item < MaxMint, 0);
        *item = *item+1;


        let nft = SuiGameNFT {
            id: object::new(ctx),
            name: string::utf8(b"SuiGameNFT"),
            description: string::utf8(b"SuiGameNFT"),
            url:  url::new_unsafe_from_bytes(b"https://suitickets.netlify.app/image/claim3.png"),
            degree: 0,
            subDegree: 0,
            feedTime: 0,
            hashrate: 0,
            hp:  0,
            str:  0,
            mag:  0,
            inT:  0,
            gold:  0
        };
        for(u64 i=0;i<MaxDegree;i++){
            vector::push_back(&mut nft.bMedalNFTs, false);
        }

        event::emit(MintNFTEvent {
            object_id: object::uid_to_inner(&nft.id),
            creator: sender,
            name: nft.name,
        });
        transfer::public_transfer(nft, sender);
    }
    public entry fun mintInvite( pool: &mut NFTPool,inviteAddr: address, ctx: &mut TxContext){
        
        let sender = tx_context::sender(ctx);
        assert!(!table::contains(&pool.addressMint, sender), 0);
        mint(pool, ctx);

        if (!table::contains(&pool.addressInvite, sender)) {
            table::add(&mut pool.addressInvite, sender, inviteAddr);
        }   
    }
    public entry fun feed(pool: &mut NFTPool,nft: &mut SuiGameNFT,  coins: vector<coin::Coin<SUI>>,clock: &Clock, ctx: &mut TxContext) { 
        assert!(nft.degree <= MaxDegree, 0);
        assert!(nft.feedTime+FeedDt < clock::timestamp_ms(clock), 1);
        
        if (!table::contains(&pool.addressInvite, sender)) {

            let coin = get_coin_from_vec(coins, FeedAmount, ctx);
            balance::join(&mut pool.addressVault, coin::into_balance(coin));
            
        }
        else{
            let addr1 = table::borrow(pool.addressInvite, sender);
            if (!table::contains(&pool.addressInvite, addr1)) {

                let coin1 = get_coin_from_vec(coins, FeedAmount*90/100, ctx);
                balance::join(&mut pool.addressVault, coin::into_balance(coin));

                let coin2 = get_coin_from_vec(coins, FeedAmount*10/100, ctx);
                balance::join(&mut addr1, coin::into_balance(coin2));
            }
            else{
                let addr2 = table::borrow(pool.addressInvite, addr1);
                let coin1 = get_coin_from_vec(coins, FeedAmount*85/100, ctx);
                balance::join(&mut pool.addressVault, coin::into_balance(coin));
                let coin2 = get_coin_from_vec(coins, FeedAmount*10/100, ctx);
                balance::join(&mut addr1, coin::into_balance(coin2));
                let coin3 = get_coin_from_vec(coins, FeedAmount*5/100, ctx);
                balance::join(&mut addr2, coin::into_balance(coin2));
            }
        }

        nft.subDegree += 1;
        if(nft.subDegree >= nft.degree)
        {
            nft.degree +=1;
            nft.subDegree =0;
        }
        nft.feedTime = clock::timestamp_ms(clock);
    }

    public entry fun MintMedalNFT(nft: &mut SuiGameNFT,u64 iDegree, ctx: &mut TxContext){
        assert!(nft.degree >= iDegree, 0);
        if(nft.degree == iDegree){
            assert!(nft.subDegree == iDegree, 0);
        }
        assert!(nft.bMedalNFTs[iDegree] == false, 1);
        nft.bMedalNFTs[iDegree] = true;
        
        let medalNft = MedalNFT{
            id: object::new(ctx),
            name: string::utf8(b"SuiGameMedalNFT"),
            description: string::utf8(b"SuiGameMedalNFT"),
            url:  url::new_unsafe_from_bytes(b""),
        } 

        if(iDegree==1) {
            medalNft.name=string::utf8(b"scorpioMedal");
        } else if(iDegree==2){
            medalNft.name=string::utf8(b"aquariusMedal");
        } else if(iDegree==3){
            medalNft.name=string::utf8(b"piscesMedal");
        }else if(iDegree==4){
            medalNft.name=string::utf8(b"ariesMedal");
        } else if(iDegree==5){
          medalNft.name=string::utf8(b"taurusMedal");
        } else if(iDegree==6){
          medalNft.name=string::utf8(b"geminiMedal");
        } else if(iDegree==7){
            medalNft.name=string::utf8(b"cancerMedal");
        } else if(iDegree==8){
             medalNft.name=string::utf8(b"leoMedal");
        } else if(iDegree==9){
            medalNft.name=string::utf8(b"virgoMedal");
        } else if(iDegree==10){
            medalNft.name=string::utf8(b"libraMedal");
        } else if(iDegree==11){
            medalNft.name=string::utf8(b"scorpioMedal");
        } else if(iDegree==12){
            medalNft.name=string::utf8(b"sagittariusMedal");
        }

        let sender = tx_context::sender(ctx);
        transfer::public_transfer(medalNft, sender);
    }
    public entry fun burn(nft: SuiGameNFT) {
        let SuiGameNFT { id, name: _, description: _, url: _,degree,subDegree,feedTime,hashrate,hp,str,mag,inT,gold } = nft;
        object::delete(id)
    }

    fun get_coin_from_vec<T>(coins: vector<coin::Coin<T>>, amount: u64, ctx: &mut TxContext): coin::Coin<T>{
        let merged_coins_in = vector::pop_back(&mut coins);
        pay::join_vec(&mut merged_coins_in, coins);
        assert!(coin::value(&merged_coins_in) >= amount, EInsufficientFunds);

        let coin_out = coin::split(&mut merged_coins_in, amount, ctx);

        if (coin::value(&merged_coins_in) > 0) {
            transfer::public_transfer(
                merged_coins_in,
                tx_context::sender(ctx)
            )
        } else {
            coin::destroy_zero(merged_coins_in)
        };

        coin_out
    }
}
