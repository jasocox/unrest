function testForm() {
  this.do("ur-form tests")
    .setHash("#ur-form-demo")
    .wait("#id_first_name")
    .checkResults("ur-form-demo ur-form")
    .changeValue("#id_first_name","Testy")
    .changeValue("#id_last_name","Larou")
    .changeValue("#id_email","testy@example.com")
    .changeValue("#id_phone_number","541-908-0704")
    .checkResults("ur-form-demo ur-form")
    .checkResults(function getData() { return uR.form.current.getData() })
    .changeValue("#id_first_name","")
    .changeValue("#id_last_name","")
    .changeValue("#id_email","")
    .changeValue("#id_phone_number","")
    .checkResults("ur-form-demo ur-form")
    .done("ur-form is great!")
}

konsole.addCommands(testForm)
