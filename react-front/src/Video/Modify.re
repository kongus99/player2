type user =
  | Verify;

[@react.component]
let make = () => {
  let (modalVisible, setModalVisible) = React.useState(() => false);
  let (state, setState) = React.useState(() => Verify);

  Bootstrap.(
    <>
      <Button onClick={() => {setModalVisible(_ => true)}}>
        {React.string("+")}
      </Button>
      <Modal
        size="lg" show=modalVisible onHide={() => setModalVisible(_ => false)}>
        <Modal.Body>
          {switch (state) {
           | Verify => <Verify onVerified=Js.log />
           }}
        </Modal.Body>
      </Modal>
    </>
  );
};
