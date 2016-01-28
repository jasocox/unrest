<ur-input>
  <label for={ id } if={ label } class={ required: required }>{ label }</label>
  <input if={ tagname == "textinput" } type={ type } name={ name } id={ id } onkeyup={ onKeyUp } onblur={ showErrors }
         placeholder={ placeholder } required={ required } minlength={ minlength } valid={ !errors.length }
         class={ empty:empty } value={ value } autocomplete="off">
  <select if={ tagname == "select" } onchange={ onChange } id={ id } name={ name }>
    <option if={ placeholder } value="">{ placeholder }</option>
    <option each={ choice in choice_tuples } value={ choice[0] }>{ choice[1] }</option>
  </select>
  <ul class="errorlist" if={ errors.length && show_errors}>
    <li class="error fa-exclamation-circle fa" each={ error in errors }> { error }</li>
  </ul>

  var self = this;
  onChange(e) {
    this.showErrors(e);
    this.onKeyUp(e);
  }

  onKeyUp(e) {
    var value = e.target.value;
    if (this.last_value == value) { return; }
    this.last_value = value;
    this.errors = [];
    this.empty = !value;
    if (this.required && !value.length) {
      this.errors.push(this.verbose_name + " is required.");
    }
    else if (value.length < this.minlength) {
      var type = (["number","tel"].indexOf(this.type) == -1)?" characters.":" numbers.";
      this.errors.push(this.verbose_name + " must be at least " + this.minlength + type);
    }
    else if (this.type == "email" && !/[^\s@]+@[^\s@]+\.[^\s@]+/.test(value)) {
      this.errors.push("Please enter a valid email address.")
    }
    if (!this.errors.length) { this.bounceValidate(value,this); }
    this.update();
  }
  showErrors(e) {
    this.show_errors = true;
    this.update();
  }
  this.on("mount", function() {
    // name is kind of a reserved word for riot since <element name="some_name"> appears as this.some_name
    // if the schema.name == "name" then it causes massive issues
    this._name = (typeof(this.name) == "object")?this.name[0]:this.name;
    this.verbose_name = this.verbose_name || this.label || this.placeholder || this._name;
    if (!this.label) { this.placeholder = this.placeholder || this.verbose_name; }
    this.id = this.id || "id_" + this._name + this.parent.suffix;
    this.validate = this.validate || function() {};
    this.type = this.type || "text";
    if (this.required == undefined) { this.required = true; }
    this.value = this.value || "";
    this.bounceValidate = uR.debounce(this.validate,500);
    this.onKeyUp({target:{value:this.value}});
    this.tagname = "textinput";
    if (this.type == "select") {
      this.tagname = "select";
      this.verbose_choices = this.verbose_choices || this.choices;
      this.choice_tuples = [];
      for (var i=0;i<this.choices.length;i++) {
        this.choice_tuples.push([this.choices[i],this.verbose_choices[i]]);
      }
    }
    if (this.parent && this.parent.fields) { this.parent.fields.push(this); }

    // This interval validates the fields after autocomplete, since there's no easy way to handle it via js
    var interval = setTimeout(function() {
      var e = document.querySelector("#"+self.id);
      if (e && e.value) {
        clearInterval(interval);
        self.onChange({target: e});
      }
    },1000);
    this.update();
  });
  this.on("update", function() {
    if (!this.parent.inputs) { this.parent.inputs = {} }
    if (this.id) { this.parent.inputs[this._name] = document.getElementById(this.id); }
    this.parent.update();
  });
</ur-input>

<ur-form>
  <form autocomplete="off" onsubmit={ submit } name="form_element" class={ opts.form_class }>
    <ur-input each={ parent.schema } class="{ name } { type }"/>
    <yield/>
    <ul class="errorlist" if={ non_field_errors.length }>
      <li class="error fa-exclamation-circle fa" each={ error in non_field_errors }> { error }</li>
      <li>
        If you need assistance contact
        <a href="mailto:support@homerapp.com">mailto:support@homerapp.com</a>
      </li>
    </ul>
    <button disabled={ !valid } class="btn blue">{ button_text }</button>
  </form>

  var that = this;
  submit(e) {
    if (this.parent.submit) {
      this.parent.submit(this);
    } else {
      uR.ajax({
        url: this.opts.action,
        type: this.opts.method,
        form: this.form_element,
        loading_attribute: "mask",
        success: function(data) {
          if (that.parent && that.parent.ajax_success) { that.parent.ajax_success(data); }
        },
        that: that
      });
    }
  }

  this.on("mount",function() {
    this.suffix = this.opts.suffix || "";
    this.button_text = this.opts.button_text || "Submit";
    this.fields = [];
    this.update();
  });
  this.on("update", function() {
    this.parent.update();
  });
  this.on("update",function() {
    this.valid = true;
    this.hide_errors = false;
    uR.forEach(this.fields,function(field) {
      that.valid = that.valid && !field.errors.length;
      // hide errors unless a field with errors is marked as show_errors
      that.hide_errors = that.hide_errors && !field.errors.length && !field.show_errors;
    })
  });

</ur-form>

<ur-formset>
  <ur-form each={ form,i in forms } suffix={ "_"+i } button_text="Add">
    <div class="message font-20" if={ next }>
      <b>{ name }</b> has been successfully added!<br /> Add more children or click <b>Next</b> to continue.
    </div>
  </ur-form>
  <button class="btn btn-blue" disabled={ !valid }>Next</button>
  var self = this;
  this.forms = [];
  this.schema = HOMER.schema.child;
  this.on("mount",function() {
    this.forms.push({schema:HOMER.schema.child});
    this.update();
  });
  submit (element) {
    var form_data = {}
    for (var key in element.inputs) { form_data[key] = element.inputs[key].value }
    uR.ajax({
      type: "POST",
      url: this.opts.action,
      data: form_data,
      target: element.root,
      that: element,
      loading_attribute: "mask",
      success: function(data) { element.name = form_data.name; self.update();}
    });
  }
</ur-formset>