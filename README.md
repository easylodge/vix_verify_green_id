# VixverifyGreenId

Ruby gem to make requests to Vix Verify's Green ID Identity Verification service. Website: [https://www.vixverify.com](https://www.vixverify.com/greenid-services/)

GreenID Documentation https://vixverify.atlassian.net/wiki/spaces/GREEN/overview?homepageId=8880204

## Installation

Add this line to your application's Gemfile:

    gem 'vix_verify_green_id'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vix_verify_green_id

Then run install generator:

	rails g vix_verify_green_id:install

Then run migrations:

    rake db:migrate


## Usage

Example Request Entity:

{
  honorific: "Mr",
  surname: "Doe",
  given_name: "John",
  middle_names: "William",
  date_of_birth: "04/08/1993",
  current_address: {
    country: "AU",
    postcode: 2290,
    state: "NSW",
    street_number: "Level",
    street_type: "ST",
    street: "1/60",
    suburb: "Charlestown"
  },
  previous_address: {
    country: "AU",
    postcode: 2290,
    state: "NSW",
    street_number: "Level",
    street_type: "ST",
    street: "2/60",
    suburb: "Rharlestown"
  },
  home_phone: "1234567890",
  mobile_phone: "0412345678",
  work_phone: "0987654321",
  email_address: "first@example.com",
  alternative_email_address: "second@example.com",
  drivers_licence_number: "123456",
  drivers_licence_state_code: "NSW",
  drivers_licence_card_number: "1234567890",
  passport_country_code: "Australian - Born in Australia",
  passport_number: "1234567890",
  medicare_middle_initial_on_card: "W",
  medicare_card_number: "1234567890",
  medicare_reference_number: 1,
  medicare_card_color: "G",
  medicare_card_expiry: "08/2024"
}

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/vix_verify_green_id. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the VixVerifyGreenId project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vix_verify_green_id/blob/master/CODE_OF_CONDUCT.md).
