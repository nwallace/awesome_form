# AwesomeForm

AwesomeForm makes it easy to write a form object for your views without
polluting your model with logic that doesn't belong there.

## Usage

### A simple Rails example

```ruby
class SignUpForm
  include AwesomeForm

  fields :email, :password, :password_confirmation

  validates :password, confirmation: true

  wraps :user do
     assigns :email,    to: :email
     assigns :password, to: :password
  end
end

class User < ActiveRecord::Base
  validates :email,    presence: true
  validates :password, presence: true
end

class UserController
  def create
    sign_up_params = params.require(:sign_up_form)
                           .permit(:email, :password, :password_confirmation)
                           .merge(user: User.new)
    @sign_up_form = SignUpForm.new(sign_up_params)
    if @sign_up_form.valid?
      @sign_up_form.save!
      redirect_to @sign_up_form.user, notice: "Registration complete!"
    else
      render :new
    end
  end
end
```

### A more complex example
```ruby
class SignUpForm
  include AwesomeForm

  fields :email, :password, :password_confirmation, :newsletter_ids,
         :birth_day, :birth_month, :birth_year

  validates :password, confirmation: true

  wraps :user do
     assigns :email,     to: :email
     assigns :password,  to: :password
     assigns :birthdate,
               to: ->(form) {
                 Date.new(form.birth_year, form.birth_month, form.birth_day)
               },
               reverse: ->(form, user) {
                 form.birth_year  = user.birthdate.year
                 form.birth_month = user.birthdate.month
                 form.birth_day   = user.birthdate.day
               },
               include_errors: :birth_year
     assigns :subscriptions,
               to: ->(form, user) {
                 form.newsletter_ids.map do |id|
                   Subscription.new(newsletter_id: id, user: user)
                   end
               },
               reverse: ->(form, user) {
                 form.newsletter_ids = user.subscriptions.pluck(:newsletter_id)
               }
  end
end

class User < ActiveRecord::Base
  validates :email,    presence: true
  validates :password, presence: true

  has_many :subscriptions, autosave: true
  has_many :newsletters, through: :subscriptions
end
```

## To-dos

- provide hooks for customization/overrides
  - if it turns out ActiveRecord deserves its own defaults, make that a
    separate module
- implement associations (`has_many`, etc) to permit `fields_for`
