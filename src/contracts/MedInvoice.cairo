#[starknet::contract]
mod MedInvoiceContract {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp, get_contract_address};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
        use starknet::storage::StoragePointerWriteAccess; // Add this line
        use starknet::storage::StoragePointerReadAccess;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::security::reentrancyguard::ReentrancyGuardComponent;
    // use array::ArrayTrait;
    // use option::OptionTrait;

    // Assuming u256 is available or aliased appropriately
    // from starknet::u256; // Or a library providing u256
    // use array::ArrayTrait;
    // use option::OptionTrait;

    // Assuming u256 is available or aliased appropriately
    // from starknet::u256; // Or a library providing u256

    const SUBSCRIPTION_AMOUNT: u256 = 10000000000000000000; // 10 tokens with 18 decimals (10 * 10^18)
    const SUBSCRIPTION_PERIOD: u64 = 365 * 24 * 60 * 60; // 365 days in seconds

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: ReentrancyGuardComponent, storage: reentrancy, event: ReentrancyGuardEvent);
    // Component implementations
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl ReentrancyGuardInternalImpl = ReentrancyGuardComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        file_list: LegacyMap<ContractAddress, Array<felt252>>,
        medi_token_address: ContractAddress,
        subscription_end_times: LegacyMap<ContractAddress, u64>,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        reentrancy: ReentrancyGuardComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FileSaved: FileSaved,
        NewSubscription: NewSubscription,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat] ReentrancyGuardEvent: ReentrancyGuardComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct FileSaved {
        #[key]
        user: ContractAddress,
        file: felt252,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct NewSubscription {
        #[key]
        subscriber: ContractAddress,
        end_time: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState, medi_token: ContractAddress, initial_owner: ContractAddress) {
        self.ownable.initializer(initial_owner);
        self.medi_token_address.write(medi_token);
    }

    #[abi(embed_v0)]
    impl MedInvoiceContractImpl of IMedInvoiceContract<ContractState> {
        fn save_file(ref self: ContractState, file: felt252) {
            assert(file != 0, 'File content cannot be empty'); // Basic check for felt252
            let caller = get_caller_address();
            let token_dispatcher = IERC20Dispatcher { contract_address: self.medi_token_address.read() };
            let balance = token_dispatcher.balance_of(caller);
            assert(balance >= u256 { low: 1, high: 0 }, 'PPT_TOKEN_HOLDING_REQUIRED'); // Assuming 1 full token, not 1 wei

            let mut user_files = self.file_list.read(caller);
            user_files.append(file);
            self.file_list.write(caller, user_files);

            self.emit(FileSaved { user: caller, file: file, timestamp: get_block_timestamp() });
        }

        // fn get_files(self: @ContractState) -> Array<felt252> {
        //     let caller = get_caller_address();
        //     let token_dispatcher = IERC20Dispatcher { contract_address: self.ppt_token_address.read() };
        //     let balance = token_dispatcher.balance_of(caller);
        //     assert(balance >= u256 { low: 1, high: 0 }, 'PPT_TOKEN_HOLDING_REQUIRED');

        //     self.file_list.read(caller)
        // }

        // fn get_user_tokens(self: @ContractState) -> u256 {
        //     let caller = get_caller_address();
        //     let token_dispatcher = IERC20Dispatcher { contract_address: self.ppt_token_address.read() };
        //     token_dispatcher.balance_of(caller)
        // }

        // fn is_subscribed(self: @ContractState, user: ContractAddress) -> bool {
        //     self.subscription_end_times.read(user) > get_block_timestamp()
        // }

        // fn get_subscription_details(self: @ContractState) -> (bool, u64) {
        //     let caller = get_caller_address();
        //     let user_end_time = self.subscription_end_times.read(caller);
        //     let exists = user_end_time > 0;
        //     (exists, user_end_time)
        // }

        // fn get_subscription_end_date(self: @ContractState, user: ContractAddress) -> u64 {
        //     self.subscription_end_times.read(user)
        // }

        // fn subscribe(ref self: ContractState) {
        //     self.reentrancy.start();
        //     let caller = get_caller_address();
        //     assert(!self.is_subscribed(caller), 'ALREADY_SUBSCRIBED');

        //     let token_dispatcher = IERC20Dispatcher { contract_address: self.ppt_token_address.read() };
            
        //     // User must have approved this contract to spend SUBSCRIPTION_AMOUNT of their PPT tokens
        //     let contract_addr = get_contract_address();
        //     let success = token_dispatcher.transfer_from(caller, contract_addr, SUBSCRIPTION_AMOUNT);
        //     assert(success, 'PPT_TRANSFER_FAILED');

        //     let end_time = get_block_timestamp() + SUBSCRIPTION_PERIOD;
        //     self.subscription_end_times.write(caller, end_time);
            
        //     self.emit(NewSubscription { subscriber: caller, end_time: end_time });
        //     self.reentrancy.end();
        // }

        // fn withdraw_tokens(ref self: ContractState, amount: u256) {
        //     self.ownable.assert_only_owner();
        //     let owner_address = self.ownable.owner();
        //     let token_dispatcher = IERC20Dispatcher { contract_address: self.ppt_token_address.read() };
        //     let success = token_dispatcher.transfer(owner_address, amount);
        //     assert(success, 'PPT_WITHDRAWAL_FAILED');
        // }
    }

    // Define the external interface trait
    #[starknet::interface]
    trait IMedInvoiceContract<TContractState> {
        fn save_file(ref self: TContractState, file: felt252);
        // fn get_files(self: @TContractState) -> Array<felt252>;
        // fn get_user_tokens(self: @TContractState) -> u256;
        // fn is_subscribed(self: @TContractState, user: ContractAddress) -> bool;
        // fn get_subscription_details(self: @TContractState) -> (bool, u64);
        // fn get_subscription_end_date(self: @TContractState, user: ContractAddress) -> u64;
        // fn subscribe(ref self: TContractState);
        // fn withdraw_tokens(ref self: TContractState, amount: u256);
    }
}