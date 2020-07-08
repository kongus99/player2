open Types;
type user =
  | Unverified
  | Unpersisted(unpersisted);

[@react.component]
let make = () => {
  let (modalVisible, setModalVisible) = React.useState(() => false);
  let (state, setState) = React.useState(() => Unverified);

  Bootstrap.(
    <>
      <Button
        onClick={() => {
          setState(_ => Unverified);
          setModalVisible(_ => true);
        }}>
        {React.string("+")}
      </Button>
      <Modal
        size="lg" show=modalVisible onHide={() => setModalVisible(_ => false)}>
        <Modal.Body>
          {switch (state) {
           | Unverified =>
             <Verify onVerified={uv => setState(_ => Unpersisted(uv))} />
           | Unpersisted(unpersisted) =>
             <Persist unpersisted onPersist=Js.log />
           }}
        </Modal.Body>
      </Modal>
    </>
  );
};
